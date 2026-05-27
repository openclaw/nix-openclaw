import fs from "node:fs";
import path from "node:path";
import { pathToFileURL } from "node:url";

const args = process.argv.slice(2);
const argValue = (flag: string): string | null => {
  const idx = args.indexOf(flag);
  if (idx === -1 || idx + 1 >= args.length) return null;
  return args[idx + 1];
};

const repo = argValue("--repo") ?? process.cwd();
const outPath = argValue("--out") ?? path.join(process.cwd(), "nix/generated/openclaw-config-options.nix");
const schemaRev = argValue("--rev") ?? process.env.OPENCLAW_SCHEMA_REV ?? null;

const schemaPath = path.join(repo, "src/config/zod-schema.ts");
const schemaUrl = pathToFileURL(schemaPath).href;

const loadSchema = async (): Promise<Record<string, unknown>> => {
  const mod = await import(schemaUrl);
  const schema = mod.OpenClawSchema;
  if (!schema || typeof schema.toJSONSchema !== "function") {
    console.error(`OpenClawSchema not found at ${schemaPath}`);
    process.exit(1);
  }
  return schema.toJSONSchema({
    target: "draft-07",
    unrepresentable: "any",
  }) as Record<string, unknown>;
};

const main = async (): Promise<void> => {
  const schema = await loadSchema();
  const definitions: Record<string, unknown> =
    (schema.definitions as Record<string, unknown>) ||
    (schema.$defs as Record<string, unknown>) ||
    {};

const stringify = (value: string): string => {
  const escaped = value.replace(/\\/g, "\\\\").replace(/"/g, "\\\"");
  return `"${escaped}"`;
};

const nixAttr = (key: string): string => {
  if (/^[A-Za-z_][A-Za-z0-9_']*$/.test(key)) return key;
  return stringify(key);
};

const nixLiteral = (value: unknown): string => {
  if (value === null) return "null";
  if (typeof value === "string") return stringify(value);
  if (typeof value === "number") return Number.isFinite(value) ? String(value) : "null";
  if (typeof value === "boolean") return value ? "true" : "false";
  if (Array.isArray(value)) {
    return `[ ${value.map(nixLiteral).join(" ")} ]`;
  }
  return "null";
};

type JsonSchema = Record<string, unknown>;

const resolveRef = (ref: string): JsonSchema | null => {
  const prefixDefs = "#/definitions/";
  const prefixDefsAlt = "#/$defs/";
  if (ref.startsWith(prefixDefs)) {
    const name = ref.slice(prefixDefs.length);
    return (definitions[name] as JsonSchema) || null;
  }
  if (ref.startsWith(prefixDefsAlt)) {
    const name = ref.slice(prefixDefsAlt.length);
    return (definitions[name] as JsonSchema) || null;
  }
  return null;
};

const deref = (input: JsonSchema, seen: Set<string>): JsonSchema => {
  if (input.$ref && typeof input.$ref === "string") {
    const ref = input.$ref as string;
    if (seen.has(ref)) {
      return {};
    }
    const resolved = resolveRef(ref);
    if (!resolved) return {};
    const nextSeen = new Set(seen);
    nextSeen.add(ref);
    return deref(resolved, nextSeen);
  }
  return input;
};

const isNullSchema = (value: unknown): boolean => {
  if (!value || typeof value !== "object") return false;
  const schemaObj = value as JsonSchema;
  if (schemaObj.type === "null") return true;
  if (Array.isArray(schemaObj.type)) return schemaObj.type.includes("null");
  return false;
};

const stripNullable = (schemaObj: JsonSchema): { schema: JsonSchema; nullable: boolean } => {
  const schema = deref(schemaObj, new Set());
  if (schema.anyOf && Array.isArray(schema.anyOf)) {
    const entries = schema.anyOf as JsonSchema[];
    const nullable = entries.some(isNullSchema);
    const next = entries.filter((entry) => !isNullSchema(entry));
    return {
      schema: { ...schema, anyOf: next },
      nullable,
    };
  }
  if (schema.oneOf && Array.isArray(schema.oneOf)) {
    const entries = schema.oneOf as JsonSchema[];
    const nullable = entries.some(isNullSchema);
    const next = entries.filter((entry) => !isNullSchema(entry));
    return {
      schema: { ...schema, oneOf: next },
      nullable,
    };
  }
  if (Array.isArray(schema.type)) {
    const nullable = schema.type.includes("null");
    const nextTypes = schema.type.filter((t) => t !== "null");
    const nextSchema = { ...schema };
    if (nextTypes.length === 1) {
      nextSchema.type = nextTypes[0];
    } else {
      nextSchema.type = nextTypes;
    }
    return { schema: nextSchema, nullable };
  }
  return { schema, nullable: false };
};

const typeForSchema = (schemaObj: JsonSchema, indent: string, pathSegments: string[] = []): string => {
  const { schema, nullable } = stripNullable(schemaObj);
  const typeExpr = baseTypeForSchema(schema, indent, pathSegments);
  if (nullable) {
    return `t.nullOr (${typeExpr})`;
  }
  return typeExpr;
};

const oneOfTypeForSchemas = (entries: JsonSchema[], indent: string, pathSegments: string[]): string => {
  const parts = Array.from(
    new Set(entries.map((entry) => typeForSchema(entry, indent, pathSegments)))
  );
  if (parts.length === 1) return parts[0];
  return `t.oneOf [ ${parts.map((part) => `(${part})`).join(" ")} ]`;
};

const baseTypeForSchema = (schemaObj: JsonSchema, indent: string, pathSegments: string[]): string => {
  const schema = deref(schemaObj, new Set());
  if (schema.const !== undefined) {
    return `t.enum [ ${nixLiteral(schema.const)} ]`;
  }
  if (Array.isArray(schema.enum)) {
    const values = schema.enum.map((value) => nixLiteral(value)).join(" ");
    return `t.enum [ ${values} ]`;
  }

  if (schema.anyOf && Array.isArray(schema.anyOf) && schema.anyOf.length > 0) {
    const entries = schema.anyOf as JsonSchema[];
    const objectUnion = objectUnionTypeForSchemas(entries, indent);
    if (objectUnion) return objectUnion;
    return oneOfTypeForSchemas(entries, indent, pathSegments);
  }

  if (schema.oneOf && Array.isArray(schema.oneOf) && schema.oneOf.length > 0) {
    const entries = schema.oneOf as JsonSchema[];
    const objectUnion = objectUnionTypeForSchemas(entries, indent);
    if (objectUnion) return objectUnion;
    return oneOfTypeForSchemas(entries, indent, pathSegments);
  }

  if (schema.allOf && Array.isArray(schema.allOf) && schema.allOf.length > 0) {
    return "t.anything";
  }

  const schemaType = schema.type;
  if (Array.isArray(schemaType) && schemaType.length > 0) {
    return oneOfTypeForSchemas(
      schemaType.map((entry) => ({ type: entry })),
      indent,
      pathSegments
    );
  }

  switch (schemaType) {
    case "string":
      return "t.str";
    case "number":
      return "t.number";
    case "integer":
      return "t.int";
    case "boolean":
      return "t.bool";
    case "array": {
      const items = (schema.items as JsonSchema) || {};
      return `t.listOf (${typeForSchema(items, indent, pathSegments)})`;
    }
    case "object":
      return objectTypeForSchema(schema, indent, pathSegments);
    case undefined:
      if (schema.properties || schema.additionalProperties) {
        return objectTypeForSchema(schema, indent, pathSegments);
      }
      return "t.anything";
    default:
      return "t.anything";
  }
};

const objectUnionTypeForSchemas = (entries: JsonSchema[], indent: string): string | null => {
  const discriminator = "source";
  const variants = entries.map((entry) => deref(entry, new Set()));
  const propsByVariant = variants.map((entry) => (entry.properties as Record<string, JsonSchema>) || null);
  if (propsByVariant.some((props) => props === null)) return null;
  const requiredByVariant = variants.map((entry) => new Set((entry.required as string[]) || []));

  const sourceValues = propsByVariant.map((props) => {
    const source = deref((props as Record<string, JsonSchema>)[discriminator] || {}, new Set());
    if (typeof source.const === "string") return source.const;
    if (Array.isArray(source.enum) && source.enum.length === 1 && typeof source.enum[0] === "string") {
      return source.enum[0] as string;
    }
    return null;
  });
  if (sourceValues.some((value) => value === null)) return null;

  const uniqueSourceValues = Array.from(new Set(sourceValues as string[]));
  if (uniqueSourceValues.length !== sourceValues.length) return null;

  const merged: Record<string, JsonSchema[]> = {};
  for (const props of propsByVariant as Record<string, JsonSchema>[]) {
    for (const [key, value] of Object.entries(props)) {
      if (!merged[key]) merged[key] = [];
      merged[key].push(value);
    }
  }
  const dedupeSchemas = (schemas: JsonSchema[]): JsonSchema[] => {
    const byKey: Record<string, JsonSchema> = {};
    for (const schema of schemas) {
      byKey[JSON.stringify(deref(schema, new Set()))] = schema;
    }
    return Object.values(byKey);
  };

  const nextIndent = `${indent}  `;
  const keys = Object.keys(merged).sort((a, b) => {
    if (a === discriminator) return -1;
    if (b === discriminator) return 1;
    return a.localeCompare(b);
  });
  const inner = keys
    .map((key) => {
      if (key === discriminator) {
        return renderOption(key, { enum: uniqueSourceValues }, true, nextIndent);
      }
      const schemas = dedupeSchemas(merged[key]);
      const schema = schemas.length === 1 ? schemas[0] : { anyOf: schemas };
      const required =
        propsByVariant.every((props) => key in (props as Record<string, JsonSchema>)) &&
        requiredByVariant.every((requiredKeys) => requiredKeys.has(key));
      return renderOption(key, schema, required, nextIndent);
    })
    .join("\n");

  return `t.submodule { options = {\n${inner}\n${indent}}; }`;
};

const allowsPluginChannelConfigs = (pathSegments: string[]): boolean =>
  pathSegments.length === 1 && pathSegments[0] === "channels";

const objectTypeForSchema = (schema: JsonSchema, indent: string, pathSegments: string[]): string => {
  const properties = (schema.properties as Record<string, JsonSchema>) || {};
  const requiredList = new Set((schema.required as string[]) || []);
  const keys = Object.keys(properties);

  if (keys.length === 0) {
    if (schema.additionalProperties && typeof schema.additionalProperties === "object") {
      const valueType = typeForSchema(schema.additionalProperties as JsonSchema, indent);
      return `t.attrsOf (${valueType})`;
    }
    if (schema.additionalProperties === true) {
      return "t.attrs";
    }
    return "t.attrs";
  }

  const nextIndent = `${indent}  `;
  const inner = keys
    .sort()
    .map((key) =>
      renderOption(key, properties[key], requiredList.has(key), nextIndent, [...pathSegments, key])
    )
    .join("\n");
  const freeform = allowsPluginChannelConfigs(pathSegments)
    ? " freeformType = t.attrsOf t.anything;"
    : "";

  return `t.submodule {${freeform} options = {\n${inner}\n${indent}}; }`;
};

const renderOption = (
  key: string,
  schemaObj: JsonSchema,
  required: boolean,
  indent: string,
  pathSegments: string[] = [key]
): string => {
  const schema = deref(schemaObj, new Set());
  const description = typeof schema.description === "string" ? schema.description : null;
  const hasSchemaDefault = schema.default !== undefined;
  const effectiveRequired = required && !hasSchemaDefault;
  const baseTypeExpr = typeForSchema(schema, indent, pathSegments);
  const typeExpr =
    !effectiveRequired && !baseTypeExpr.startsWith("t.nullOr")
      ? `t.nullOr (${baseTypeExpr})`
      : baseTypeExpr;
  const lines = [
    `${indent}${nixAttr(key)} = lib.mkOption {`,
    `${indent}  type = ${typeExpr};`,
  ];
  if (!effectiveRequired) {
    lines.push(`${indent}  default = null;`);
  }
  if (description) {
    lines.push(`${indent}  description = ${stringify(description)};`);
  }
  lines.push(`${indent}};`);
  return lines.join("\n");
};

  const rootSchema = deref(schema as JsonSchema, new Set());
  const rootProps = (rootSchema.properties as Record<string, JsonSchema>) || {};
  const requiredRoot = new Set((rootSchema.required as string[]) || []);

  const body = Object.keys(rootProps)
    .sort()
    .map((key) => renderOption(key, rootProps[key], requiredRoot.has(key), "  "))
    .join("\n\n");

  const header = schemaRev
    ? `# Generated from upstream OpenClaw schema at rev ${schemaRev}. DO NOT EDIT.`
    : "# Generated from upstream OpenClaw schema. DO NOT EDIT.";

  const output = `${header}\n# Generator: nix/scripts/generate-config-options.ts\n{ lib }:\nlet\n  t = lib.types;\nin\n{\n${body}\n}\n`;

  fs.mkdirSync(path.dirname(outPath), { recursive: true });
  fs.writeFileSync(outPath, output, "utf8");
};

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
