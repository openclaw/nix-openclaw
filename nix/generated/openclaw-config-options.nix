# Generated from upstream OpenClaw schema at rev b556fdf457b026574bf0f1e7b4914b15f3f179ce. DO NOT EDIT.
# Generator: nix/scripts/generate-config-options.ts
{ lib }:
let
  t = lib.types;
in
{
  "$schema" = lib.mkOption {
    type = t.nullOr (t.str);
    default = null;
  };

  accessGroups = lib.mkOption {
    type = t.nullOr (t.attrsOf (t.submodule { options = {
    type = lib.mkOption {
      type = t.enum [ "discord.channelAudience" "message.senders" ];
    };
    channelId = lib.mkOption {
      type = t.nullOr (t.str);
      default = null;
    };
    guildId = lib.mkOption {
      type = t.nullOr (t.str);
      default = null;
    };
    members = lib.mkOption {
      type = t.nullOr (t.attrsOf (t.listOf (t.str)));
      default = null;
    };
    membership = lib.mkOption {
      type = t.nullOr (t.enum [ "canViewChannel" ]);
      default = null;
    };
  }; }));
    default = null;
  };

  acp = lib.mkOption {
    type = t.nullOr (t.submodule { options = {
    allowedAgents = lib.mkOption {
      type = t.nullOr (t.listOf (t.str));
      default = null;
    };
    backend = lib.mkOption {
      type = t.nullOr (t.str);
      default = null;
    };
    defaultAgent = lib.mkOption {
      type = t.nullOr (t.str);
      default = null;
    };
    dispatch = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      enabled = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
    }; });
      default = null;
    };
    enabled = lib.mkOption {
      type = t.nullOr (t.bool);
      default = null;
    };
    fallbacks = lib.mkOption {
      type = t.nullOr (t.listOf (t.str));
      default = null;
    };
    runtime = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      installCommand = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
    }; });
      default = null;
    };
    stream = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      deliveryMode = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.enum [ "live" ]) (t.enum [ "final_only" ]) ]);
        default = null;
      };
      repeatSuppression = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      tagVisibility = lib.mkOption {
        type = t.nullOr (t.attrsOf (t.bool));
        default = null;
      };
    }; });
      default = null;
    };
  }; });
    default = null;
  };

  agents = lib.mkOption {
    type = t.nullOr (t.submodule { options = {
    defaults = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      authInheritance = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        agentId = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
      }; });
        default = null;
      };
      blockStreamingBreak = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.enum [ "text_end" ]) (t.enum [ "message_end" ]) ]);
        default = null;
      };
      blockStreamingChunk = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        breakPreference = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.enum [ "paragraph" ]) (t.enum [ "newline" ]) (t.enum [ "sentence" ]) ]);
          default = null;
        };
        maxChars = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        minChars = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
      }; });
        default = null;
      };
      blockStreamingCoalesce = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        idleMs = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        maxChars = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        minChars = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
      }; });
        default = null;
      };
      blockStreamingDefault = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.enum [ "off" ]) (t.enum [ "on" ]) ]);
        default = null;
      };
      bootstrapMaxChars = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      bootstrapTotalMaxChars = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      compaction = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        enabled = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
        identifierPolicy = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.enum [ "strict" ]) (t.enum [ "off" ]) ]);
          default = null;
        };
        keepRecentTokens = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        maxActiveTranscriptBytes = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.int) (t.str) ]);
          default = null;
        };
        memoryFlush = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          enabled = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          forceFlushTranscriptBytes = lib.mkOption {
            type = t.nullOr (t.oneOf [ (t.int) (t.str) ]);
            default = null;
          };
          model = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          softThresholdTokens = lib.mkOption {
            type = t.nullOr (t.int);
            default = null;
          };
        }; });
          default = null;
        };
        midTurnPrecheck = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          enabled = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
        }; });
          default = null;
        };
        mode = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.enum [ "default" ]) (t.enum [ "safeguard" ]) ]);
          default = null;
        };
        model = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        notifyUser = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
        postCompactionSections = lib.mkOption {
          type = t.nullOr (t.listOf (t.str));
          default = null;
        };
        postIndexSync = lib.mkOption {
          type = t.nullOr (t.enum [ "off" "async" "await" ]);
          default = null;
        };
        provider = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        qualityGuard = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          enabled = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          maxRetries = lib.mkOption {
            type = t.nullOr (t.int);
            default = null;
          };
        }; });
          default = null;
        };
        recentTurnsPreserve = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        thinkingLevel = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.enum [ "off" "minimal" "low" "medium" "high" "xhigh" "adaptive" "max" "ultra" ]) (t.enum [ "inherit" ]) ]);
          default = null;
        };
        timeoutSeconds = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
      }; });
        default = null;
      };
      contextInjection = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.enum [ "always" ]) (t.enum [ "continuation-skip" ]) (t.enum [ "never" ]) ]);
        default = null;
      };
      contextLimits = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        memoryGetMaxChars = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        postCompactionMaxChars = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
      }; });
        default = null;
      };
      contextPruning = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        hardClear = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          enabled = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          placeholder = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
        }; });
          default = null;
        };
        mode = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.enum [ "off" ]) (t.enum [ "cache-ttl" ]) ]);
          default = null;
        };
        tools = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          allow = lib.mkOption {
            type = t.nullOr (t.listOf (t.str));
            default = null;
          };
          deny = lib.mkOption {
            type = t.nullOr (t.listOf (t.str));
            default = null;
          };
        }; });
          default = null;
        };
        ttl = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
      }; });
        default = null;
      };
      cwd = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      decisionModel = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      elevatedDefault = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.enum [ "off" ]) (t.enum [ "on" ]) (t.enum [ "ask" ]) (t.enum [ "full" ]) ]);
        default = null;
      };
      embeddedAgent = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        cyberFailover = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          cooloffMs = lib.mkOption {
            type = t.nullOr (t.int);
            default = null;
          };
          mode = lib.mkOption {
            type = t.nullOr (t.oneOf [ (t.enum [ "auto" ]) (t.enum [ "off" ]) ]);
            default = null;
          };
          model = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
        }; });
          default = null;
        };
        executionContract = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.enum [ "default" ]) (t.enum [ "strict-agentic" ]) ]);
          default = null;
        };
        projectSettingsPolicy = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.enum [ "trusted" ]) (t.enum [ "sanitize" ]) (t.enum [ "ignore" ]) ]);
          default = null;
        };
      }; });
        default = null;
      };
      experimental = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        decisionAssistance = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
        localModelLean = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
      }; });
        default = null;
      };
      fastModeDefault = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.bool) (t.enum [ "auto" ]) (t.enum [ "ultrafast" ]) ]);
        default = null;
      };
      heartbeat = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        accountId = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        activeHours = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          end = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          start = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          timezone = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
        }; });
          default = null;
        };
        agentId = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        directPolicy = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.enum [ "allow" ]) (t.enum [ "block" ]) ]);
          default = null;
        };
        every = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        isolatedSession = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
        lightContext = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
        model = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        prompt = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        session = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        target = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        timeoutSeconds = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        to = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
      }; });
        default = null;
      };
      humanDelay = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        maxMs = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        minMs = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        mode = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.enum [ "off" ]) (t.enum [ "natural" ]) (t.enum [ "custom" ]) ]);
          default = null;
        };
      }; });
        default = null;
      };
      imageMaxDimensionPx = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      imageModel = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
        fallbacks = lib.mkOption {
          type = t.nullOr (t.listOf (t.str));
          default = null;
        };
        primary = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        timeoutMs = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
      }; }) ]);
        default = null;
      };
      imageQuality = lib.mkOption {
        type = t.nullOr (t.enum [ "auto" "efficient" "balanced" "high" ]);
        default = null;
      };
      maxConcurrent = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      mediaMaxMb = lib.mkOption {
        type = t.nullOr (t.number);
        default = null;
      };
      mediaModels = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        image = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
          fallbacks = lib.mkOption {
            type = t.nullOr (t.listOf (t.str));
            default = null;
          };
          primary = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          timeoutMs = lib.mkOption {
            type = t.nullOr (t.int);
            default = null;
          };
        }; }) ]);
          default = null;
        };
        music = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
          fallbacks = lib.mkOption {
            type = t.nullOr (t.listOf (t.str));
            default = null;
          };
          primary = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          timeoutMs = lib.mkOption {
            type = t.nullOr (t.int);
            default = null;
          };
        }; }) ]);
          default = null;
        };
        video = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
          fallbacks = lib.mkOption {
            type = t.nullOr (t.listOf (t.str));
            default = null;
          };
          primary = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          timeoutMs = lib.mkOption {
            type = t.nullOr (t.int);
            default = null;
          };
        }; }) ]);
          default = null;
        };
      }; });
        default = null;
      };
      model = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
        fallbacks = lib.mkOption {
          type = t.nullOr (t.listOf (t.str));
          default = null;
        };
        primary = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
      }; }) ]);
        default = null;
      };
      modelPolicy = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        allow = lib.mkOption {
          type = t.nullOr (t.listOf (t.str));
          default = null;
        };
      }; });
        default = null;
      };
      modelSelectionScope = lib.mkOption {
        type = t.nullOr (t.enum [ "session" "agent" "global" ]);
        default = null;
      };
      models = lib.mkOption {
        type = t.nullOr (t.attrsOf (t.submodule { options = {
        agentRuntime = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          id = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
        }; });
          default = null;
        };
        alias = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        codeMode = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
        params = lib.mkOption {
          type = t.nullOr (t.attrsOf (t.anything));
          default = null;
        };
        pickerRuntimes = lib.mkOption {
          type = t.nullOr (t.listOf (t.str));
          default = null;
        };
        streaming = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
      }; }));
        default = null;
      };
      params = lib.mkOption {
        type = t.nullOr (t.attrsOf (t.anything));
        default = null;
      };
      pdfMaxMb = lib.mkOption {
        type = t.nullOr (t.number);
        default = null;
      };
      pdfMaxPages = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      pdfModel = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
        fallbacks = lib.mkOption {
          type = t.nullOr (t.listOf (t.str));
          default = null;
        };
        primary = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        timeoutMs = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
      }; }) ]);
        default = null;
      };
      reasoningDefault = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.enum [ "off" ]) (t.enum [ "on" ]) (t.enum [ "stream" ]) ]);
        default = null;
      };
      repoRoot = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      sandbox = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        backend = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        browser = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          allowHostControl = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          autoStart = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          autoStartTimeoutMs = lib.mkOption {
            type = t.nullOr (t.int);
            default = null;
          };
          binds = lib.mkOption {
            type = t.nullOr (t.listOf (t.str));
            default = null;
          };
          cdpPort = lib.mkOption {
            type = t.nullOr (t.int);
            default = null;
          };
          cdpSourceRange = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          containerPrefix = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          enabled = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          headless = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          image = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          network = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          noVncEnabled = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          noVncPort = lib.mkOption {
            type = t.nullOr (t.int);
            default = null;
          };
          vncPort = lib.mkOption {
            type = t.nullOr (t.int);
            default = null;
          };
        }; });
          default = null;
        };
        docker = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          apparmorProfile = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          binds = lib.mkOption {
            type = t.nullOr (t.listOf (t.str));
            default = null;
          };
          capDrop = lib.mkOption {
            type = t.nullOr (t.listOf (t.str));
            default = null;
          };
          containerPrefix = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          cpus = lib.mkOption {
            type = t.nullOr (t.number);
            default = null;
          };
          dangerouslyAllowContainerNamespaceJoin = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          dangerouslyAllowExternalBindSources = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          dangerouslyAllowReservedContainerTargets = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          dns = lib.mkOption {
            type = t.nullOr (t.listOf (t.str));
            default = null;
          };
          env = lib.mkOption {
            type = t.nullOr (t.attrsOf (t.str));
            default = null;
          };
          extraHosts = lib.mkOption {
            type = t.nullOr (t.listOf (t.str));
            default = null;
          };
          gpus = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          image = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          memory = lib.mkOption {
            type = t.nullOr (t.oneOf [ (t.str) (t.number) ]);
            default = null;
          };
          memorySwap = lib.mkOption {
            type = t.nullOr (t.oneOf [ (t.str) (t.number) ]);
            default = null;
          };
          network = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          pidsLimit = lib.mkOption {
            type = t.nullOr (t.int);
            default = null;
          };
          readOnlyRoot = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          seccompProfile = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          setupCommand = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          tmpfs = lib.mkOption {
            type = t.nullOr (t.listOf (t.str));
            default = null;
          };
          ulimits = lib.mkOption {
            type = t.nullOr (t.attrsOf (t.oneOf [ (t.str) (t.number) (t.submodule { options = {
            hard = lib.mkOption {
              type = t.nullOr (t.int);
              default = null;
            };
            soft = lib.mkOption {
              type = t.nullOr (t.int);
              default = null;
            };
          }; }) ]));
            default = null;
          };
          user = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          workdir = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
        }; });
          default = null;
        };
        mode = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.enum [ "off" ]) (t.enum [ "non-main" ]) (t.enum [ "all" ]) ]);
          default = null;
        };
        prune = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          idleHours = lib.mkOption {
            type = t.nullOr (t.int);
            default = null;
          };
          maxAgeDays = lib.mkOption {
            type = t.nullOr (t.int);
            default = null;
          };
        }; });
          default = null;
        };
        scope = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.enum [ "session" ]) (t.enum [ "agent" ]) (t.enum [ "shared" ]) ]);
          default = null;
        };
        sessionToolsVisibility = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.enum [ "spawned" ]) (t.enum [ "all" ]) ]);
          default = null;
        };
        ssh = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          certificateData = lib.mkOption {
            type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
            source = lib.mkOption {
              type = t.enum [ "env" "file" "exec" "store" ];
            };
            id = lib.mkOption {
              type = t.str;
            };
            provider = lib.mkOption {
              type = t.str;
            };
          }; }) ]);
            default = null;
          };
          certificateFile = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          command = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          identityData = lib.mkOption {
            type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
            source = lib.mkOption {
              type = t.enum [ "env" "file" "exec" "store" ];
            };
            id = lib.mkOption {
              type = t.str;
            };
            provider = lib.mkOption {
              type = t.str;
            };
          }; }) ]);
            default = null;
          };
          identityFile = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          knownHostsData = lib.mkOption {
            type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
            source = lib.mkOption {
              type = t.enum [ "env" "file" "exec" "store" ];
            };
            id = lib.mkOption {
              type = t.str;
            };
            provider = lib.mkOption {
              type = t.str;
            };
          }; }) ]);
            default = null;
          };
          knownHostsFile = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          strictHostKeyChecking = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          target = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          updateHostKeys = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          workspaceRoot = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
        }; });
          default = null;
        };
        workspaceAccess = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.enum [ "none" ]) (t.enum [ "ro" ]) (t.enum [ "rw" ]) ]);
          default = null;
        };
        workspaceRoot = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
      }; });
        default = null;
      };
      sessionStore = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        agentId = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
      }; });
        default = null;
      };
      silentReply = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        group = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.enum [ "allow" ]) (t.enum [ "disallow" ]) ]);
          default = null;
        };
      }; });
        default = null;
      };
      skills = lib.mkOption {
        type = t.nullOr (t.listOf (t.str));
        default = null;
      };
      skipBootstrap = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      skipOptionalBootstrapFiles = lib.mkOption {
        type = t.nullOr (t.listOf (t.enum [ "SOUL.md" "USER.md" "HEARTBEAT.md" "IDENTITY.md" ]));
        default = null;
      };
      startupContext = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        applyOn = lib.mkOption {
          type = t.nullOr (t.listOf (t.oneOf [ (t.enum [ "new" ]) (t.enum [ "reset" ]) ]));
          default = null;
        };
        dailyMemoryDays = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        enabled = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
        maxFileBytes = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        maxFileChars = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        maxTotalChars = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
      }; });
        default = null;
      };
      subagents = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        allowAgents = lib.mkOption {
          type = t.nullOr (t.listOf (t.str));
          default = null;
        };
        announceTimeoutMs = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        archiveAfterMinutes = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        delegationMode = lib.mkOption {
          type = t.nullOr (t.enum [ "suggest" "prefer" ]);
          default = null;
        };
        maxChildrenPerAgent = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
          description = "Maximum number of active children a single agent session can spawn (default: 5).";
        };
        maxConcurrent = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
          description = "Maximum concurrent child-agent runs per immediate spawning/controller session (default: 8). Independent sessions have independent budgets.";
        };
        maxSpawnDepth = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
          description = "Maximum nesting depth for sub-agent spawning. Default: 5; 1 makes direct children leaves.";
        };
        model = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
          fallbacks = lib.mkOption {
            type = t.nullOr (t.listOf (t.str));
            default = null;
          };
          primary = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
        }; }) ]);
          default = null;
        };
        requireAgentId = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
        runTimeoutSeconds = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        thinking = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
      }; });
        default = null;
      };
      systemAgent = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        agentId = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
      }; });
        default = null;
      };
      thinkingDefault = lib.mkOption {
        type = t.nullOr (t.enum [ "off" "minimal" "low" "medium" "high" "xhigh" "adaptive" "max" "ultra" ]);
        default = null;
      };
      timeoutSeconds = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      toolProgressDetail = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.enum [ "explain" ]) (t.enum [ "raw" ]) ]);
        default = null;
      };
      typingIntervalSeconds = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      typingMode = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.enum [ "never" ]) (t.enum [ "instant" ]) (t.enum [ "thinking" ]) (t.enum [ "message" ]) ]);
        default = null;
      };
      userTimezone = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      utilityModel = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      verboseDefault = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.enum [ "off" ]) (t.enum [ "on" ]) (t.enum [ "full" ]) ]);
        default = null;
      };
      voiceModel = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
        fallbacks = lib.mkOption {
          type = t.nullOr (t.listOf (t.str));
          default = null;
        };
        primary = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        timeoutMs = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
      }; }) ]);
        default = null;
      };
      workspace = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
    }; });
      default = null;
    };
    entries = lib.mkOption {
      type = t.nullOr (t.attrsOf (t.submodule { options = {
      agentDir = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      bootstrapMaxChars = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      bootstrapTotalMaxChars = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      contextInjection = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.enum [ "always" ]) (t.enum [ "continuation-skip" ]) (t.enum [ "never" ]) ]);
        default = null;
      };
      contextLimits = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        memoryGetMaxChars = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        postCompactionMaxChars = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
      }; });
        default = null;
      };
      cwd = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      decisionModel = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      default = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      description = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      embeddedAgent = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        executionContract = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.enum [ "default" ]) (t.enum [ "strict-agentic" ]) ]);
          default = null;
        };
      }; });
        default = null;
      };
      experimental = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        localModelLean = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
      }; });
        default = null;
      };
      fastModeDefault = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.bool) (t.enum [ "auto" ]) (t.enum [ "ultrafast" ]) ]);
        default = null;
      };
      groupChat = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        historyLimit = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        mentionPatterns = lib.mkOption {
          type = t.nullOr (t.listOf (t.str));
          default = null;
        };
        unmentionedInbound = lib.mkOption {
          type = t.nullOr (t.enum [ "user_request" "room_event" ]);
          default = null;
        };
      }; });
        default = null;
      };
      heartbeat = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        accountId = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        activeHours = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          end = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          start = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          timezone = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
        }; });
          default = null;
        };
        directPolicy = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.enum [ "allow" ]) (t.enum [ "block" ]) ]);
          default = null;
        };
        every = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        isolatedSession = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
        lightContext = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
        model = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        prompt = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        session = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        target = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        timeoutSeconds = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        to = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
      }; });
        default = null;
      };
      humanDelay = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        maxMs = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        minMs = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        mode = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.enum [ "off" ]) (t.enum [ "natural" ]) (t.enum [ "custom" ]) ]);
          default = null;
        };
      }; });
        default = null;
      };
      identity = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        avatar = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        emoji = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        name = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        theme = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
      }; });
        default = null;
      };
      memory = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        search = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          cache = lib.mkOption {
            type = t.nullOr (t.submodule { options = {
            enabled = lib.mkOption {
              type = t.nullOr (t.bool);
              default = null;
            };
          }; });
            default = null;
          };
          documentInputType = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          enabled = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          experimental = lib.mkOption {
            type = t.nullOr (t.submodule { options = {
            sessionMemory = lib.mkOption {
              type = t.nullOr (t.bool);
              default = null;
            };
          }; });
            default = null;
          };
          extraPaths = lib.mkOption {
            type = t.nullOr (t.listOf (t.oneOf [ (t.str) (t.submodule { options = {
            path = lib.mkOption {
              type = t.str;
            };
            pattern = lib.mkOption {
              type = t.nullOr (t.str);
              default = null;
            };
          }; }) ]));
            default = null;
          };
          fallback = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          inputType = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          local = lib.mkOption {
            type = t.nullOr (t.submodule { options = {
            modelPath = lib.mkOption {
              type = t.nullOr (t.str);
              default = null;
            };
          }; });
            default = null;
          };
          model = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          multimodal = lib.mkOption {
            type = t.nullOr (t.submodule { options = {
            enabled = lib.mkOption {
              type = t.nullOr (t.bool);
              default = null;
            };
            maxFileBytes = lib.mkOption {
              type = t.nullOr (t.int);
              default = null;
            };
            modalities = lib.mkOption {
              type = t.nullOr (t.listOf (t.oneOf [ (t.enum [ "image" ]) (t.enum [ "audio" ]) (t.enum [ "all" ]) ]));
              default = null;
            };
          }; });
            default = null;
          };
          outputDimensionality = lib.mkOption {
            type = t.nullOr (t.int);
            default = null;
          };
          provider = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          query = lib.mkOption {
            type = t.nullOr (t.submodule { options = {
            maxResults = lib.mkOption {
              type = t.nullOr (t.int);
              default = null;
            };
            minScore = lib.mkOption {
              type = t.nullOr (t.number);
              default = null;
            };
          }; });
            default = null;
          };
          queryInputType = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          rememberAcrossConversations = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          remote = lib.mkOption {
            type = t.nullOr (t.submodule { options = {
            apiKey = lib.mkOption {
              type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
              source = lib.mkOption {
                type = t.enum [ "env" "file" "exec" "store" ];
              };
              id = lib.mkOption {
                type = t.str;
              };
              provider = lib.mkOption {
                type = t.str;
              };
            }; }) ]);
              default = null;
            };
            baseUrl = lib.mkOption {
              type = t.nullOr (t.str);
              default = null;
            };
            batch = lib.mkOption {
              type = t.nullOr (t.submodule { options = {
              enabled = lib.mkOption {
                type = t.nullOr (t.bool);
                default = null;
              };
            }; });
              default = null;
            };
            headers = lib.mkOption {
              type = t.nullOr (t.attrsOf (t.str));
              default = null;
            };
          }; });
            default = null;
          };
          sources = lib.mkOption {
            type = t.nullOr (t.listOf (t.oneOf [ (t.enum [ "memory" ]) (t.enum [ "sessions" ]) ]));
            default = null;
          };
          store = lib.mkOption {
            type = t.nullOr (t.submodule { options = {
            fts = lib.mkOption {
              type = t.nullOr (t.submodule { options = {
              tokenizer = lib.mkOption {
                type = t.nullOr (t.oneOf [ (t.enum [ "unicode61" ]) (t.enum [ "trigram" ]) ]);
                default = null;
              };
            }; });
              default = null;
            };
            vector = lib.mkOption {
              type = t.nullOr (t.submodule { options = {
              enabled = lib.mkOption {
                type = t.nullOr (t.bool);
                default = null;
              };
              extensionPath = lib.mkOption {
                type = t.nullOr (t.str);
                default = null;
              };
            }; });
              default = null;
            };
          }; });
            default = null;
          };
        }; });
          default = null;
        };
      }; });
        default = null;
      };
      model = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
        fallbacks = lib.mkOption {
          type = t.nullOr (t.listOf (t.str));
          default = null;
        };
        primary = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
      }; }) ]);
        default = null;
      };
      modelPolicy = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        allow = lib.mkOption {
          type = t.nullOr (t.listOf (t.str));
          default = null;
        };
      }; });
        default = null;
      };
      models = lib.mkOption {
        type = t.nullOr (t.attrsOf (t.submodule { options = {
        agentRuntime = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          id = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
        }; });
          default = null;
        };
        alias = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        codeMode = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
        params = lib.mkOption {
          type = t.nullOr (t.attrsOf (t.anything));
          default = null;
        };
        pickerRuntimes = lib.mkOption {
          type = t.nullOr (t.listOf (t.str));
          default = null;
        };
        streaming = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
      }; }));
        default = null;
      };
      name = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      params = lib.mkOption {
        type = t.nullOr (t.attrsOf (t.anything));
        default = null;
      };
      reasoningDefault = lib.mkOption {
        type = t.nullOr (t.enum [ "on" "off" "stream" ]);
        default = null;
      };
      runtime = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        type = lib.mkOption {
          type = t.enum [ "embedded" "acp" ];
        };
        acp = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          agent = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          backend = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          cwd = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          mode = lib.mkOption {
            type = t.nullOr (t.enum [ "persistent" "oneshot" ]);
            default = null;
          };
        }; });
          default = null;
        };
      }; });
        default = null;
      };
      sandbox = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        backend = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        browser = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          allowHostControl = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          autoStart = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          autoStartTimeoutMs = lib.mkOption {
            type = t.nullOr (t.int);
            default = null;
          };
          binds = lib.mkOption {
            type = t.nullOr (t.listOf (t.str));
            default = null;
          };
          cdpPort = lib.mkOption {
            type = t.nullOr (t.int);
            default = null;
          };
          cdpSourceRange = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          containerPrefix = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          enabled = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          headless = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          image = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          network = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          noVncEnabled = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          noVncPort = lib.mkOption {
            type = t.nullOr (t.int);
            default = null;
          };
          vncPort = lib.mkOption {
            type = t.nullOr (t.int);
            default = null;
          };
        }; });
          default = null;
        };
        docker = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          apparmorProfile = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          binds = lib.mkOption {
            type = t.nullOr (t.listOf (t.str));
            default = null;
          };
          capDrop = lib.mkOption {
            type = t.nullOr (t.listOf (t.str));
            default = null;
          };
          containerPrefix = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          cpus = lib.mkOption {
            type = t.nullOr (t.number);
            default = null;
          };
          dangerouslyAllowContainerNamespaceJoin = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          dangerouslyAllowExternalBindSources = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          dangerouslyAllowReservedContainerTargets = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          dns = lib.mkOption {
            type = t.nullOr (t.listOf (t.str));
            default = null;
          };
          env = lib.mkOption {
            type = t.nullOr (t.attrsOf (t.str));
            default = null;
          };
          extraHosts = lib.mkOption {
            type = t.nullOr (t.listOf (t.str));
            default = null;
          };
          gpus = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          image = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          memory = lib.mkOption {
            type = t.nullOr (t.oneOf [ (t.str) (t.number) ]);
            default = null;
          };
          memorySwap = lib.mkOption {
            type = t.nullOr (t.oneOf [ (t.str) (t.number) ]);
            default = null;
          };
          network = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          pidsLimit = lib.mkOption {
            type = t.nullOr (t.int);
            default = null;
          };
          readOnlyRoot = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          seccompProfile = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          setupCommand = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          tmpfs = lib.mkOption {
            type = t.nullOr (t.listOf (t.str));
            default = null;
          };
          ulimits = lib.mkOption {
            type = t.nullOr (t.attrsOf (t.oneOf [ (t.str) (t.number) (t.submodule { options = {
            hard = lib.mkOption {
              type = t.nullOr (t.int);
              default = null;
            };
            soft = lib.mkOption {
              type = t.nullOr (t.int);
              default = null;
            };
          }; }) ]));
            default = null;
          };
          user = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          workdir = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
        }; });
          default = null;
        };
        mode = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.enum [ "off" ]) (t.enum [ "non-main" ]) (t.enum [ "all" ]) ]);
          default = null;
        };
        prune = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          idleHours = lib.mkOption {
            type = t.nullOr (t.int);
            default = null;
          };
          maxAgeDays = lib.mkOption {
            type = t.nullOr (t.int);
            default = null;
          };
        }; });
          default = null;
        };
        scope = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.enum [ "session" ]) (t.enum [ "agent" ]) (t.enum [ "shared" ]) ]);
          default = null;
        };
        sessionToolsVisibility = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.enum [ "spawned" ]) (t.enum [ "all" ]) ]);
          default = null;
        };
        ssh = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          certificateData = lib.mkOption {
            type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
            source = lib.mkOption {
              type = t.enum [ "env" "file" "exec" "store" ];
            };
            id = lib.mkOption {
              type = t.str;
            };
            provider = lib.mkOption {
              type = t.str;
            };
          }; }) ]);
            default = null;
          };
          certificateFile = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          command = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          identityData = lib.mkOption {
            type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
            source = lib.mkOption {
              type = t.enum [ "env" "file" "exec" "store" ];
            };
            id = lib.mkOption {
              type = t.str;
            };
            provider = lib.mkOption {
              type = t.str;
            };
          }; }) ]);
            default = null;
          };
          identityFile = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          knownHostsData = lib.mkOption {
            type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
            source = lib.mkOption {
              type = t.enum [ "env" "file" "exec" "store" ];
            };
            id = lib.mkOption {
              type = t.str;
            };
            provider = lib.mkOption {
              type = t.str;
            };
          }; }) ]);
            default = null;
          };
          knownHostsFile = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          strictHostKeyChecking = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          target = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          updateHostKeys = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          workspaceRoot = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
        }; });
          default = null;
        };
        workspaceAccess = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.enum [ "none" ]) (t.enum [ "ro" ]) (t.enum [ "rw" ]) ]);
          default = null;
        };
        workspaceRoot = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
      }; });
        default = null;
      };
      skills = lib.mkOption {
        type = t.nullOr (t.listOf (t.str));
        default = null;
      };
      skillsLimits = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        maxSkillsPromptChars = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
      }; });
        default = null;
      };
      subagents = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        allowAgents = lib.mkOption {
          type = t.nullOr (t.listOf (t.str));
          default = null;
        };
        delegateToolsTo = lib.mkOption {
          type = t.nullOr (t.listOf (t.str));
          default = null;
        };
        delegationMode = lib.mkOption {
          type = t.nullOr (t.enum [ "suggest" "prefer" ]);
          default = null;
        };
        model = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
          fallbacks = lib.mkOption {
            type = t.nullOr (t.listOf (t.str));
            default = null;
          };
          primary = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
        }; }) ]);
          default = null;
        };
        requireAgentId = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
        thinking = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
      }; });
        default = null;
      };
      thinkingDefault = lib.mkOption {
        type = t.nullOr (t.enum [ "off" "minimal" "low" "medium" "high" "xhigh" "adaptive" "max" "ultra" ]);
        default = null;
      };
      toolProgressDetail = lib.mkOption {
        type = t.nullOr (t.enum [ "explain" "raw" ]);
        default = null;
      };
      tools = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        agentToAgent = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          send = lib.mkOption {
            type = t.nullOr (t.listOf (t.str));
            default = null;
          };
        }; });
          default = null;
        };
        allow = lib.mkOption {
          type = t.nullOr (t.listOf (t.str));
          default = null;
        };
        alsoAllow = lib.mkOption {
          type = t.nullOr (t.listOf (t.str));
          default = null;
        };
        byProvider = lib.mkOption {
          type = t.nullOr (t.attrsOf (t.submodule { options = {
          allow = lib.mkOption {
            type = t.nullOr (t.listOf (t.str));
            default = null;
          };
          alsoAllow = lib.mkOption {
            type = t.nullOr (t.listOf (t.str));
            default = null;
          };
          deny = lib.mkOption {
            type = t.nullOr (t.listOf (t.str));
            default = null;
          };
          profile = lib.mkOption {
            type = t.nullOr (t.oneOf [ (t.enum [ "minimal" ]) (t.enum [ "coding" ]) (t.enum [ "messaging" ]) (t.enum [ "full" ]) ]);
            default = null;
          };
        }; }));
          default = null;
        };
        codeMode = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.bool) (t.enum [ "auto" ]) (t.submodule { options = {
          enabled = lib.mkOption {
            type = t.nullOr (t.oneOf [ (t.bool) (t.enum [ "auto" ]) ]);
            default = null;
          };
          executor = lib.mkOption {
            type = t.nullOr (t.enum [ "node" "quickjs" ]);
            default = null;
          };
          maxOutputBytes = lib.mkOption {
            type = t.nullOr (t.int);
            default = null;
          };
          maxPendingToolCalls = lib.mkOption {
            type = t.nullOr (t.int);
            default = null;
          };
          maxSearchLimit = lib.mkOption {
            type = t.nullOr (t.int);
            default = null;
          };
          maxSnapshotBytes = lib.mkOption {
            type = t.nullOr (t.int);
            default = null;
          };
          memoryLimitBytes = lib.mkOption {
            type = t.nullOr (t.int);
            default = null;
          };
          mode = lib.mkOption {
            type = t.nullOr (t.enum [ "only" ]);
            default = null;
          };
          searchDefaultLimit = lib.mkOption {
            type = t.nullOr (t.int);
            default = null;
          };
          snapshotTtlSeconds = lib.mkOption {
            type = t.nullOr (t.int);
            default = null;
          };
          timeoutMs = lib.mkOption {
            type = t.nullOr (t.int);
            default = null;
          };
        }; }) ]);
          default = null;
        };
        deny = lib.mkOption {
          type = t.nullOr (t.listOf (t.str));
          default = null;
        };
        elevated = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          allowFrom = lib.mkOption {
            type = t.nullOr (t.attrsOf (t.listOf (t.oneOf [ (t.str) (t.number) ])));
            default = null;
          };
          enabled = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
        }; });
          default = null;
        };
        exec = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          applyPatch = lib.mkOption {
            type = t.nullOr (t.submodule { options = {
            allowModels = lib.mkOption {
              type = t.nullOr (t.listOf (t.str));
              default = null;
            };
            enabled = lib.mkOption {
              type = t.nullOr (t.bool);
              default = null;
            };
            workspaceOnly = lib.mkOption {
              type = t.nullOr (t.bool);
              default = null;
            };
          }; });
            default = null;
          };
          approvalRunningNoticeMs = lib.mkOption {
            type = t.nullOr (t.int);
            default = null;
          };
          ask = lib.mkOption {
            type = t.nullOr (t.enum [ "off" "on-miss" "always" ]);
            default = null;
          };
          backgroundMs = lib.mkOption {
            type = t.nullOr (t.int);
            default = null;
          };
          cleanupMs = lib.mkOption {
            type = t.nullOr (t.int);
            default = null;
          };
          commandHighlighting = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          grantExpiryDays = lib.mkOption {
            type = t.nullOr (t.int);
            default = null;
          };
          host = lib.mkOption {
            type = t.nullOr (t.enum [ "auto" "sandbox" "gateway" "node" ]);
            default = null;
          };
          mode = lib.mkOption {
            type = t.nullOr (t.enum [ "deny" "allowlist" "ask" "auto" "full" ]);
            default = null;
          };
          node = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          notifyOnExit = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          notifyOnExitEmptySuccess = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          pathPrepend = lib.mkOption {
            type = t.nullOr (t.listOf (t.str));
            default = null;
          };
          reviewer = lib.mkOption {
            type = t.nullOr (t.submodule { options = {
            fastMode = lib.mkOption {
              type = t.nullOr (t.bool);
              default = null;
            };
            model = lib.mkOption {
              type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
              fallbacks = lib.mkOption {
                type = t.nullOr (t.listOf (t.str));
                default = null;
              };
              primary = lib.mkOption {
                type = t.nullOr (t.str);
                default = null;
              };
            }; }) ]);
              default = null;
            };
            thinking = lib.mkOption {
              type = t.nullOr (t.enum [ "minimal" "low" "medium" "high" "xhigh" "max" ]);
              default = null;
            };
            timeoutMs = lib.mkOption {
              type = t.nullOr (t.int);
              default = null;
            };
          }; });
            default = null;
          };
          safeBinProfiles = lib.mkOption {
            type = t.nullOr (t.attrsOf (t.submodule { options = {
            allowedValueFlags = lib.mkOption {
              type = t.nullOr (t.listOf (t.str));
              default = null;
            };
            deniedFlags = lib.mkOption {
              type = t.nullOr (t.listOf (t.str));
              default = null;
            };
            maxPositional = lib.mkOption {
              type = t.nullOr (t.int);
              default = null;
            };
            minPositional = lib.mkOption {
              type = t.nullOr (t.int);
              default = null;
            };
          }; }));
            default = null;
          };
          safeBinTrustedDirs = lib.mkOption {
            type = t.nullOr (t.listOf (t.str));
            default = null;
          };
          safeBins = lib.mkOption {
            type = t.nullOr (t.listOf (t.str));
            default = null;
          };
          security = lib.mkOption {
            type = t.nullOr (t.enum [ "deny" "allowlist" "full" ]);
            default = null;
          };
          strictInlineEval = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          timeoutSeconds = lib.mkOption {
            type = t.nullOr (t.int);
            default = null;
          };
        }; });
          default = null;
        };
        fs = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          workspaceOnly = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
        }; });
          default = null;
        };
        github = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          allowInSandbox = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          gitAuthor = lib.mkOption {
            type = t.nullOr (t.submodule { options = {
            email = lib.mkOption {
              type = t.nullOr (t.str);
              default = null;
            };
            name = lib.mkOption {
              type = t.nullOr (t.str);
              default = null;
            };
          }; });
            default = null;
          };
          kind = lib.mkOption {
            type = t.nullOr (t.enum [ "oauth" ]);
            default = null;
          };
          profileId = lib.mkOption {
            type = t.str;
          };
        }; });
          default = null;
        };
        loopDetection = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          enabled = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
        }; });
          default = null;
        };
        message = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          actions = lib.mkOption {
            type = t.nullOr (t.submodule { options = {
            allow = lib.mkOption {
              type = t.nullOr (t.listOf (t.str));
              default = null;
            };
          }; });
            default = null;
          };
          broadcast = lib.mkOption {
            type = t.nullOr (t.submodule { options = {
            enabled = lib.mkOption {
              type = t.nullOr (t.bool);
              default = null;
            };
          }; });
            default = null;
          };
          crossContext = lib.mkOption {
            type = t.nullOr (t.submodule { options = {
            allowAcrossProviders = lib.mkOption {
              type = t.nullOr (t.bool);
              default = null;
            };
            allowWithinProvider = lib.mkOption {
              type = t.nullOr (t.bool);
              default = null;
            };
            marker = lib.mkOption {
              type = t.nullOr (t.submodule { options = {
              enabled = lib.mkOption {
                type = t.nullOr (t.bool);
                default = null;
              };
              prefix = lib.mkOption {
                type = t.nullOr (t.str);
                default = null;
              };
              suffix = lib.mkOption {
                type = t.nullOr (t.str);
                default = null;
              };
            }; });
              default = null;
            };
          }; });
            default = null;
          };
        }; });
          default = null;
        };
        profile = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.enum [ "minimal" ]) (t.enum [ "coding" ]) (t.enum [ "messaging" ]) (t.enum [ "full" ]) ]);
          default = null;
        };
        sandbox = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          tools = lib.mkOption {
            type = t.nullOr (t.submodule { options = {
            allow = lib.mkOption {
              type = t.nullOr (t.listOf (t.str));
              default = null;
            };
            alsoAllow = lib.mkOption {
              type = t.nullOr (t.listOf (t.str));
              default = null;
            };
            deny = lib.mkOption {
              type = t.nullOr (t.listOf (t.str));
              default = null;
            };
          }; });
            default = null;
          };
        }; });
          default = null;
        };
        swarm = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.bool) (t.submodule { options = {
          defaultAgentId = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          enabled = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          maxChildrenPerGroup = lib.mkOption {
            type = t.nullOr (t.int);
            default = null;
          };
          maxConcurrent = lib.mkOption {
            type = t.nullOr (t.int);
            default = null;
          };
          maxTotalPerGroup = lib.mkOption {
            type = t.nullOr (t.int);
            default = null;
          };
          waitTimeoutSecondsMax = lib.mkOption {
            type = t.nullOr (t.int);
            default = null;
          };
        }; }) ]);
          default = null;
        };
        toolsBySender = lib.mkOption {
          type = t.nullOr (t.attrsOf (t.submodule { options = {
          allow = lib.mkOption {
            type = t.nullOr (t.listOf (t.str));
            default = null;
          };
          alsoAllow = lib.mkOption {
            type = t.nullOr (t.listOf (t.str));
            default = null;
          };
          deny = lib.mkOption {
            type = t.nullOr (t.listOf (t.str));
            default = null;
          };
        }; }));
          default = null;
        };
      }; });
        default = null;
      };
      tts = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        auto = lib.mkOption {
          type = t.nullOr (t.enum [ "off" "always" "inbound" "tagged" ]);
          default = null;
        };
        enabled = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
        maxTextLength = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        mode = lib.mkOption {
          type = t.nullOr (t.enum [ "final" "all" ]);
          default = null;
        };
        modelOverrides = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          allowModelId = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          allowNormalization = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          allowProvider = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          allowSeed = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          allowText = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          allowVoice = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          allowVoiceSettings = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          enabled = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
        }; });
          default = null;
        };
        persona = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        personas = lib.mkOption {
          type = t.nullOr (t.attrsOf (t.submodule { options = {
          description = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          fallbackPolicy = lib.mkOption {
            type = t.nullOr (t.oneOf [ (t.enum [ "preserve-persona" ]) (t.enum [ "provider-defaults" ]) (t.enum [ "fail" ]) ]);
            default = null;
          };
          label = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          provider = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          providers = lib.mkOption {
            type = t.nullOr (t.attrsOf (t.submodule { options = {
            apiKey = lib.mkOption {
              type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
              source = lib.mkOption {
                type = t.enum [ "env" "file" "exec" "store" ];
              };
              id = lib.mkOption {
                type = t.str;
              };
              provider = lib.mkOption {
                type = t.str;
              };
            }; }) ]);
              default = null;
            };
          }; }));
            default = null;
          };
        }; }));
          default = null;
        };
        prefsPath = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        provider = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        providers = lib.mkOption {
          type = t.nullOr (t.attrsOf (t.submodule { options = {
          apiKey = lib.mkOption {
            type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
            source = lib.mkOption {
              type = t.enum [ "env" "file" "exec" "store" ];
            };
            id = lib.mkOption {
              type = t.str;
            };
            provider = lib.mkOption {
              type = t.str;
            };
          }; }) ]);
            default = null;
          };
        }; }));
          default = null;
        };
        summaryModel = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        timeoutMs = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
      }; });
        default = null;
      };
      typingMode = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.enum [ "never" ]) (t.enum [ "instant" ]) (t.enum [ "thinking" ]) (t.enum [ "message" ]) ]);
        default = null;
      };
      utilityModel = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      verboseDefault = lib.mkOption {
        type = t.nullOr (t.enum [ "off" "on" "full" ]);
        default = null;
      };
      workspace = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
    }; }));
      default = null;
    };
    ownership = lib.mkOption {
      type = t.nullOr (t.enum [ "explicit" ]);
      default = null;
    };
  }; });
    default = null;
  };

  approvals = lib.mkOption {
    type = t.nullOr (t.submodule { options = {
    exec = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      agentFilter = lib.mkOption {
        type = t.nullOr (t.listOf (t.str));
        default = null;
      };
      enabled = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      mode = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.enum [ "session" ]) (t.enum [ "targets" ]) (t.enum [ "both" ]) ]);
        default = null;
      };
      sessionFilter = lib.mkOption {
        type = t.nullOr (t.listOf (t.str));
        default = null;
      };
      targets = lib.mkOption {
        type = t.nullOr (t.listOf (t.submodule { options = {
        accountId = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        channel = lib.mkOption {
          type = t.str;
        };
        threadId = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.str) (t.number) ]);
          default = null;
        };
        to = lib.mkOption {
          type = t.str;
        };
      }; }));
        default = null;
      };
    }; });
      default = null;
    };
    plugin = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      agentFilter = lib.mkOption {
        type = t.nullOr (t.listOf (t.str));
        default = null;
      };
      enabled = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      mode = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.enum [ "session" ]) (t.enum [ "targets" ]) (t.enum [ "both" ]) ]);
        default = null;
      };
      sessionFilter = lib.mkOption {
        type = t.nullOr (t.listOf (t.str));
        default = null;
      };
      slack = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        approvers = lib.mkOption {
          type = t.nullOr (t.listOf (t.str));
          default = null;
        };
        plugins = lib.mkOption {
          type = t.nullOr (t.attrsOf (t.submodule { options = {
          approvers = lib.mkOption {
            type = t.nullOr (t.listOf (t.str));
            default = null;
          };
          tools = lib.mkOption {
            type = t.nullOr (t.attrsOf (t.submodule { options = {
            approvers = lib.mkOption {
              type = t.listOf (t.str);
            };
          }; }));
            default = null;
          };
        }; }));
          default = null;
        };
      }; });
        default = null;
      };
      targets = lib.mkOption {
        type = t.nullOr (t.listOf (t.submodule { options = {
        accountId = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        channel = lib.mkOption {
          type = t.str;
        };
        threadId = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.str) (t.number) ]);
          default = null;
        };
        to = lib.mkOption {
          type = t.str;
        };
      }; }));
        default = null;
      };
    }; });
      default = null;
    };
  }; });
    default = null;
  };

  attachments = lib.mkOption {
    type = t.nullOr (t.submodule { options = {
    ttlHours = lib.mkOption {
      type = t.nullOr (t.int);
      default = null;
    };
  }; });
    default = null;
  };

  auth = lib.mkOption {
    type = t.nullOr (t.submodule { options = {
    order = lib.mkOption {
      type = t.nullOr (t.attrsOf (t.listOf (t.str)));
      default = null;
    };
    profiles = lib.mkOption {
      type = t.nullOr (t.attrsOf (t.submodule { options = {
      displayName = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      email = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      mode = lib.mkOption {
        type = t.oneOf [ (t.enum [ "api_key" ]) (t.enum [ "aws-sdk" ]) (t.enum [ "oauth" ]) (t.enum [ "token" ]) ];
      };
      provider = lib.mkOption {
        type = t.str;
      };
    }; }));
      default = null;
    };
  }; });
    default = null;
  };

  bindings = lib.mkOption {
    type = t.nullOr (t.listOf (t.oneOf [ (t.submodule { options = {
    agentId = lib.mkOption {
      type = t.str;
    };
    comment = lib.mkOption {
      type = t.nullOr (t.str);
      default = null;
    };
    match = lib.mkOption {
      type = t.submodule { options = {
      accountId = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      channel = lib.mkOption {
        type = t.str;
      };
      guildId = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      peer = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        id = lib.mkOption {
          type = t.str;
        };
        kind = lib.mkOption {
          type = t.oneOf [ (t.enum [ "direct" ]) (t.enum [ "group" ]) (t.enum [ "channel" ]) ];
        };
      }; });
        default = null;
      };
      roles = lib.mkOption {
        type = t.nullOr (t.listOf (t.str));
        default = null;
      };
      teamId = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
    }; };
    };
    session = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      dmScope = lib.mkOption {
        type = t.nullOr (t.enum [ "main" "per-peer" "per-channel-peer" "per-account-channel-peer" ]);
        default = null;
      };
      groupScope = lib.mkOption {
        type = t.nullOr (t.enum [ "main" "per-group" ]);
        default = null;
      };
    }; });
      default = null;
    };
    type = lib.mkOption {
      type = t.nullOr (t.enum [ "route" ]);
      default = null;
    };
  }; }) (t.submodule { options = {
    acp = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      backend = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      cwd = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      label = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      mode = lib.mkOption {
        type = t.nullOr (t.enum [ "persistent" "oneshot" ]);
        default = null;
      };
    }; });
      default = null;
    };
    agentId = lib.mkOption {
      type = t.str;
    };
    comment = lib.mkOption {
      type = t.nullOr (t.str);
      default = null;
    };
    match = lib.mkOption {
      type = t.submodule { options = {
      accountId = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      channel = lib.mkOption {
        type = t.str;
      };
      guildId = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      peer = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        id = lib.mkOption {
          type = t.str;
        };
        kind = lib.mkOption {
          type = t.oneOf [ (t.enum [ "direct" ]) (t.enum [ "group" ]) (t.enum [ "channel" ]) ];
        };
      }; });
        default = null;
      };
      roles = lib.mkOption {
        type = t.nullOr (t.listOf (t.str));
        default = null;
      };
      teamId = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
    }; };
    };
    type = lib.mkOption {
      type = t.enum [ "acp" ];
    };
  }; }) ]));
    default = null;
  };

  broadcast = lib.mkOption {
    type = t.nullOr (t.submodule { options = {
    strategy = lib.mkOption {
      type = t.nullOr (t.enum [ "parallel" "sequential" ]);
      default = null;
    };
  }; });
    default = null;
  };

  browser = lib.mkOption {
    type = t.nullOr (t.submodule { options = {
    allowSystemProfileImport = lib.mkOption {
      type = t.nullOr (t.bool);
      default = null;
    };
    attachOnly = lib.mkOption {
      type = t.nullOr (t.bool);
      default = null;
    };
    cdpUrl = lib.mkOption {
      type = t.nullOr (t.str);
      default = null;
    };
    defaultProfile = lib.mkOption {
      type = t.nullOr (t.str);
      default = null;
    };
    enabled = lib.mkOption {
      type = t.nullOr (t.bool);
      default = null;
    };
    evaluateEnabled = lib.mkOption {
      type = t.nullOr (t.bool);
      default = null;
    };
    executablePath = lib.mkOption {
      type = t.nullOr (t.str);
      default = null;
    };
    extensionRelay = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      allowLegacyAuth = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
    }; });
      default = null;
    };
    extraArgs = lib.mkOption {
      type = t.nullOr (t.listOf (t.str));
      default = null;
    };
    headless = lib.mkOption {
      type = t.nullOr (t.bool);
      default = null;
    };
    noSandbox = lib.mkOption {
      type = t.nullOr (t.bool);
      default = null;
    };
    profiles = lib.mkOption {
      type = t.nullOr (t.attrsOf (t.submodule { options = {
      attachOnly = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      cdpPort = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      cdpUrl = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      driver = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.enum [ "openclaw" ]) (t.enum [ "clawd" ]) (t.enum [ "existing-session" ]) (t.enum [ "extension" ]) ]);
        default = null;
      };
      engine = lib.mkOption {
        type = t.nullOr (t.enum [ "chromium" "lightpanda" ]);
        default = null;
      };
      executablePath = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      headless = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      mcpArgs = lib.mkOption {
        type = t.nullOr (t.listOf (t.str));
        default = null;
      };
      mcpCommand = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      userDataDir = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
    }; }));
      default = null;
    };
    snapshotDefaults = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      mode = lib.mkOption {
        type = t.nullOr (t.enum [ "efficient" ]);
        default = null;
      };
    }; });
      default = null;
    };
    ssrfPolicy = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      allowIpv6UniqueLocalRange = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      allowRfc2544BenchmarkRange = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      allowedHostnames = lib.mkOption {
        type = t.nullOr (t.listOf (t.str));
        default = null;
      };
      blockedHostnames = lib.mkOption {
        type = t.nullOr (t.listOf (t.str));
        default = null;
      };
      dangerouslyAllowPrivateNetwork = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
    }; });
      default = null;
    };
    tabCleanup = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      enabled = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
    }; });
      default = null;
    };
  }; });
    default = null;
  };

  channels = lib.mkOption {
    type = t.nullOr (t.submodule { freeformType = t.attrsOf t.anything; options = {
    defaults = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      botLoopProtection = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        cooldownSeconds = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        enabled = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
        maxEventsPerWindow = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        windowSeconds = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
      }; });
        default = null;
      };
      contextVisibility = lib.mkOption {
        type = t.nullOr (t.enum [ "all" "allowlist" "allowlist_quote" ]);
        default = null;
      };
      groupPolicy = lib.mkOption {
        type = t.nullOr (t.enum [ "open" "disabled" "allowlist" ]);
        default = null;
      };
      heartbeatVisibility = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        showAlerts = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
        showOk = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
        useIndicator = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
      }; });
        default = null;
      };
      implicitMentions = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        quotedBot = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
        replyToBot = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
        threadParticipation = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
      }; });
        default = null;
      };
    }; });
      default = null;
    };
    modelByChannel = lib.mkOption {
      type = t.nullOr (t.attrsOf (t.attrsOf (t.str)));
      default = null;
    };
  }; });
    default = null;
  };

  cloudWorkers = lib.mkOption {
    type = t.nullOr (t.submodule { options = {
    desktop = lib.mkOption {
      type = t.nullOr (t.bool);
      default = null;
    };
    preparedPool = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      maxTotal = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
    }; });
      default = null;
    };
    profiles = lib.mkOption {
      type = t.nullOr (t.attrsOf (t.submodule { options = {
      install = lib.mkOption {
        type = t.nullOr (t.enum [ "bundle" "npm" ]);
        default = null;
      };
      provider = lib.mkOption {
        type = t.str;
      };
      readyWorkers = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      settings = lib.mkOption {
        type = t.nullOr (t.attrsOf (t.anything));
        default = null;
      };
      suspendAfter = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
    }; }));
      default = null;
    };
    projectProfiles = lib.mkOption {
      type = t.nullOr (t.attrsOf (t.str));
      default = null;
    };
    requiredProfile = lib.mkOption {
      type = t.nullOr (t.str);
      default = null;
    };
  }; });
    default = null;
  };

  commands = lib.mkOption {
    type = t.nullOr (t.submodule { options = {
    allowFrom = lib.mkOption {
      type = t.nullOr (t.attrsOf (t.listOf (t.oneOf [ (t.str) (t.number) ])));
      default = null;
    };
    bash = lib.mkOption {
      type = t.nullOr (t.bool);
      default = null;
    };
    bashForegroundMs = lib.mkOption {
      type = t.nullOr (t.int);
      default = null;
    };
    config = lib.mkOption {
      type = t.nullOr (t.bool);
      default = null;
    };
    debug = lib.mkOption {
      type = t.nullOr (t.bool);
      default = null;
    };
    mcp = lib.mkOption {
      type = t.nullOr (t.bool);
      default = null;
    };
    native = lib.mkOption {
      type = t.nullOr (t.oneOf [ (t.bool) (t.enum [ "auto" ]) ]);
      default = null;
    };
    nativeSkills = lib.mkOption {
      type = t.nullOr (t.oneOf [ (t.bool) (t.enum [ "auto" ]) ]);
      default = null;
    };
    ownerAllowFrom = lib.mkOption {
      type = t.nullOr (t.listOf (t.oneOf [ (t.str) (t.number) ]));
      default = null;
    };
    plugins = lib.mkOption {
      type = t.nullOr (t.bool);
      default = null;
    };
    restart = lib.mkOption {
      type = t.nullOr (t.bool);
      default = null;
    };
    text = lib.mkOption {
      type = t.nullOr (t.bool);
      default = null;
    };
  }; });
    default = null;
  };

  cron = lib.mkOption {
    type = t.nullOr (t.submodule { options = {
    enabled = lib.mkOption {
      type = t.nullOr (t.bool);
      default = null;
    };
    failureAlert = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      accountId = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      after = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      channel = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      cooldownMs = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      enabled = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      includeSkipped = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      mode = lib.mkOption {
        type = t.nullOr (t.enum [ "announce" "webhook" ]);
        default = null;
      };
      to = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
    }; });
      default = null;
    };
    sessionRetention = lib.mkOption {
      type = t.nullOr (t.oneOf [ (t.str) (t.enum [ false ]) ]);
      default = null;
    };
    skipMissedJobs = lib.mkOption {
      type = t.nullOr (t.bool);
      default = null;
    };
    triggers = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      enabled = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
    }; });
      default = null;
    };
    webhookSsrfPolicy = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      allowIpv6UniqueLocalRange = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      allowRfc2544BenchmarkRange = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      allowedHostnames = lib.mkOption {
        type = t.nullOr (t.listOf (t.str));
        default = null;
      };
      blockedHostnames = lib.mkOption {
        type = t.nullOr (t.listOf (t.str));
        default = null;
      };
      dangerouslyAllowPrivateNetwork = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
    }; });
      default = null;
    };
    webhookToken = lib.mkOption {
      type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
      source = lib.mkOption {
        type = t.enum [ "env" "file" "exec" "store" ];
      };
      id = lib.mkOption {
        type = t.str;
      };
      provider = lib.mkOption {
        type = t.str;
      };
    }; }) ]);
      default = null;
    };
  }; });
    default = null;
  };

  database = lib.mkOption {
    type = t.nullOr (t.submodule { options = {
    engine = lib.mkOption {
      type = t.nullOr (t.enum [ "sqlite" "postgres" ]);
      default = null;
    };
    postgres = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      connection = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
        source = lib.mkOption {
          type = t.enum [ "env" "file" "exec" "store" ];
        };
        id = lib.mkOption {
          type = t.str;
        };
        provider = lib.mkOption {
          type = t.str;
        };
      }; }) ]);
        default = null;
      };
      schemaPrefix = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
    }; });
      default = null;
    };
  }; });
    default = null;
  };

  desktop = lib.mkOption {
    type = t.nullOr (t.submodule { options = {
    host = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      enabled = lib.mkOption {
        type = t.bool;
      };
      managed = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      passwordFile = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      port = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
    }; });
      default = null;
    };
  }; });
    default = null;
  };

  diagnostics = lib.mkOption {
    type = t.nullOr (t.submodule { options = {
    cacheTrace = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      enabled = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
    }; });
      default = null;
    };
    enabled = lib.mkOption {
      type = t.nullOr (t.bool);
      default = null;
    };
    flags = lib.mkOption {
      type = t.nullOr (t.listOf (t.str));
      default = null;
    };
    otel = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      captureContent = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      enabled = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      endpoint = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      flushIntervalMs = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      headers = lib.mkOption {
        type = t.nullOr (t.attrsOf (t.str));
        default = null;
      };
      logs = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      logsEndpoint = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      logsExporter = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.enum [ "otlp" ]) (t.enum [ "stdout" ]) (t.enum [ "both" ]) ]);
        default = null;
      };
      metricNamePrefix = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      metrics = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      metricsEndpoint = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      protocol = lib.mkOption {
        type = t.nullOr (t.enum [ "http/protobuf" ]);
        default = null;
      };
      sampleRate = lib.mkOption {
        type = t.nullOr (t.number);
        default = null;
      };
      serviceName = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      traces = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      tracesEndpoint = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
    }; });
      default = null;
    };
  }; });
    default = null;
  };

  discovery = lib.mkOption {
    type = t.nullOr (t.submodule { options = {
    mdns = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      mode = lib.mkOption {
        type = t.nullOr (t.enum [ "off" "minimal" "full" ]);
        default = null;
      };
    }; });
      default = null;
    };
    wideArea = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      domain = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
    }; });
      default = null;
    };
  }; });
    default = null;
  };

  env = lib.mkOption {
    type = t.nullOr (t.submodule { options = {
    shellEnv = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      enabled = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      timeoutMs = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
    }; });
      default = null;
    };
    vars = lib.mkOption {
      type = t.nullOr (t.attrsOf (t.str));
      default = null;
    };
  }; });
    default = null;
  };

  gateway = lib.mkOption {
    type = t.nullOr (t.submodule { options = {
    allowRealIpFallback = lib.mkOption {
      type = t.nullOr (t.bool);
      default = null;
    };
    auth = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      allowTailscale = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      identityScopes = lib.mkOption {
        type = t.nullOr (t.attrsOf (t.listOf (t.enum [ "operator.admin" "operator.read" "operator.write" "operator.sessions.read" "operator.sessions.write" "operator.approvals" "operator.questions" "operator.pairing" "operator.talk" "operator.talk.secrets" ])));
        default = null;
      };
      mode = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.enum [ "none" ]) (t.enum [ "token" ]) (t.enum [ "password" ]) (t.enum [ "trusted-proxy" ]) ]);
        default = null;
      };
      password = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
        source = lib.mkOption {
          type = t.enum [ "env" "file" "exec" "store" ];
        };
        id = lib.mkOption {
          type = t.str;
        };
        provider = lib.mkOption {
          type = t.str;
        };
      }; }) ]);
        default = null;
      };
      rateLimit = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        exemptLoopback = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
        lockoutMs = lib.mkOption {
          type = t.nullOr (t.number);
          default = null;
        };
        maxAttempts = lib.mkOption {
          type = t.nullOr (t.number);
          default = null;
        };
        windowMs = lib.mkOption {
          type = t.nullOr (t.number);
          default = null;
        };
      }; });
        default = null;
      };
      token = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
        source = lib.mkOption {
          type = t.enum [ "env" "file" "exec" "store" ];
        };
        id = lib.mkOption {
          type = t.str;
        };
        provider = lib.mkOption {
          type = t.str;
        };
      }; }) ]);
        default = null;
      };
      trustedProxy = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        allowLoopback = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
        allowUsers = lib.mkOption {
          type = t.nullOr (t.listOf (t.str));
          default = null;
        };
        cloudflareAccessOidc = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          githubAccountIdClaim = lib.mkOption {
            type = t.str;
          };
          issuer = lib.mkOption {
            type = t.str;
          };
          providerId = lib.mkOption {
            type = t.str;
          };
        }; });
          default = null;
        };
        deviceAutoApprove = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          enabled = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          scopes = lib.mkOption {
            type = t.nullOr (t.listOf (t.str));
            default = null;
          };
        }; });
          default = null;
        };
        requiredHeaders = lib.mkOption {
          type = t.nullOr (t.listOf (t.str));
          default = null;
        };
        userHeader = lib.mkOption {
          type = t.str;
        };
      }; });
        default = null;
      };
    }; });
      default = null;
    };
    bind = lib.mkOption {
      type = t.nullOr (t.oneOf [ (t.enum [ "auto" ]) (t.enum [ "lan" ]) (t.enum [ "loopback" ]) (t.enum [ "custom" ]) (t.enum [ "tailnet" ]) ]);
      default = null;
    };
    cliAgents = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      enabled = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
    }; });
      default = null;
    };
    controlUi = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      allowExternalEmbedUrls = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      allowedOrigins = lib.mkOption {
        type = t.nullOr (t.listOf (t.str));
        default = null;
      };
      automaticallyFetchFavicons = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      basePath = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      communityInvite = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      dangerouslyAllowHostHeaderOriginFallback = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      dangerouslyDisableDeviceAuth = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      embedSandbox = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.enum [ "strict" ]) (t.enum [ "scripts" ]) (t.enum [ "trusted" ]) ]);
        default = null;
      };
      enabled = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      environment = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        color = lib.mkOption {
          type = t.enum [ "teal" "amber" "purple" "coral" "pink" "blue" "green" "red" "gray" ];
        };
        label = lib.mkOption {
          type = t.str;
        };
      }; });
        default = null;
      };
      experimental = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        chatBubbles = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
        customPlugins = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
      }; });
        default = null;
      };
      github = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        host = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        token = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
          source = lib.mkOption {
            type = t.enum [ "env" "file" "exec" "store" ];
          };
          id = lib.mkOption {
            type = t.str;
          };
          provider = lib.mkOption {
            type = t.str;
          };
        }; }) ]);
          default = null;
        };
      }; });
        default = null;
      };
      newSessionModelDefaults = lib.mkOption {
        type = t.nullOr (t.enum [ "last-used" "configured" ]);
        default = null;
      };
      root = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      sessionObserver = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
    }; });
      default = null;
    };
    customBindHost = lib.mkOption {
      type = t.nullOr (t.str);
      default = null;
    };
    github = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      apiBaseUrl = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      host = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
    }; });
      default = null;
    };
    http = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      endpoints = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        chatCompletions = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          enabled = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          images = lib.mkOption {
            type = t.nullOr (t.submodule { options = {
            allowUrl = lib.mkOption {
              type = t.nullOr (t.bool);
              default = null;
            };
            allowedMimes = lib.mkOption {
              type = t.nullOr (t.listOf (t.str));
              default = null;
            };
            maxBytes = lib.mkOption {
              type = t.nullOr (t.int);
              default = null;
            };
            maxRedirects = lib.mkOption {
              type = t.nullOr (t.int);
              default = null;
            };
            timeoutMs = lib.mkOption {
              type = t.nullOr (t.int);
              default = null;
            };
            urlAllowlist = lib.mkOption {
              type = t.nullOr (t.listOf (t.str));
              default = null;
            };
          }; });
            default = null;
          };
        }; });
          default = null;
        };
        responses = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          enabled = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          files = lib.mkOption {
            type = t.nullOr (t.submodule { options = {
            allowUrl = lib.mkOption {
              type = t.nullOr (t.bool);
              default = null;
            };
            allowedMimes = lib.mkOption {
              type = t.nullOr (t.listOf (t.str));
              default = null;
            };
            maxBytes = lib.mkOption {
              type = t.nullOr (t.int);
              default = null;
            };
            maxChars = lib.mkOption {
              type = t.nullOr (t.int);
              default = null;
            };
            maxRedirects = lib.mkOption {
              type = t.nullOr (t.int);
              default = null;
            };
            pdf = lib.mkOption {
              type = t.nullOr (t.submodule { options = {
              maxPages = lib.mkOption {
                type = t.nullOr (t.int);
                default = null;
              };
              maxPixels = lib.mkOption {
                type = t.nullOr (t.int);
                default = null;
              };
              minTextChars = lib.mkOption {
                type = t.nullOr (t.int);
                default = null;
              };
            }; });
              default = null;
            };
            timeoutMs = lib.mkOption {
              type = t.nullOr (t.int);
              default = null;
            };
            urlAllowlist = lib.mkOption {
              type = t.nullOr (t.listOf (t.str));
              default = null;
            };
          }; });
            default = null;
          };
          images = lib.mkOption {
            type = t.nullOr (t.submodule { options = {
            allowUrl = lib.mkOption {
              type = t.nullOr (t.bool);
              default = null;
            };
            allowedMimes = lib.mkOption {
              type = t.nullOr (t.listOf (t.str));
              default = null;
            };
            maxBytes = lib.mkOption {
              type = t.nullOr (t.int);
              default = null;
            };
            maxRedirects = lib.mkOption {
              type = t.nullOr (t.int);
              default = null;
            };
            timeoutMs = lib.mkOption {
              type = t.nullOr (t.int);
              default = null;
            };
            urlAllowlist = lib.mkOption {
              type = t.nullOr (t.listOf (t.str));
              default = null;
            };
          }; });
            default = null;
          };
          maxUrlParts = lib.mkOption {
            type = t.nullOr (t.int);
            default = null;
          };
        }; });
          default = null;
        };
      }; });
        default = null;
      };
      securityHeaders = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        strictTransportSecurity = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.str) (t.enum [ false ]) ]);
          default = null;
        };
      }; });
        default = null;
      };
    }; });
      default = null;
    };
    mode = lib.mkOption {
      type = t.nullOr (t.oneOf [ (t.enum [ "local" ]) (t.enum [ "remote" ]) ]);
      default = null;
    };
    nodes = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      allowSkills = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      browser = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        mode = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.enum [ "auto" ]) (t.enum [ "manual" ]) (t.enum [ "off" ]) ]);
          default = null;
        };
        node = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
      }; });
        default = null;
      };
      commands = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        allow = lib.mkOption {
          type = t.nullOr (t.listOf (t.str));
          default = null;
        };
        deny = lib.mkOption {
          type = t.nullOr (t.listOf (t.str));
          default = null;
        };
      }; });
        default = null;
      };
      pairing = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        autoApproveCidrs = lib.mkOption {
          type = t.nullOr (t.listOf (t.str));
          default = null;
        };
        autoApproveLocal = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
        sshVerify = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.bool) (t.submodule { options = {
          cidrs = lib.mkOption {
            type = t.nullOr (t.listOf (t.str));
            default = null;
          };
          identity = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          timeoutMs = lib.mkOption {
            type = t.nullOr (t.int);
            default = null;
          };
          user = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
        }; }) ]);
          default = null;
        };
      }; });
        default = null;
      };
      pluginTools = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        enabled = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
      }; });
        default = null;
      };
    }; });
      default = null;
    };
    port = lib.mkOption {
      type = t.nullOr (t.int);
      default = null;
    };
    portals = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      ingress = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        domain = lib.mkOption {
          type = t.str;
        };
        port = lib.mkOption {
          type = t.int;
        };
      }; });
        default = null;
      };
    }; });
      default = null;
    };
    projects = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      defaultRepository = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        ref = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        url = lib.mkOption {
          type = t.str;
        };
      }; });
        default = null;
      };
      nativeGitHubSearch = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
    }; });
      default = null;
    };
    publicOrigin = lib.mkOption {
      type = t.nullOr (t.str);
      default = null;
    };
    push = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      apns = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        relay = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          baseUrl = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          timeoutMs = lib.mkOption {
            type = t.nullOr (t.int);
            default = null;
          };
        }; });
          default = null;
        };
      }; });
        default = null;
      };
    }; });
      default = null;
    };
    reload = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      mode = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.enum [ "off" ]) (t.enum [ "hybrid" ]) ]);
        default = null;
      };
    }; });
      default = null;
    };
    remote = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      edgeAuth = lib.mkOption {
        type = t.nullOr (t.attrsOf (t.oneOf [ (t.str) (t.submodule { options = {
        source = lib.mkOption {
          type = t.enum [ "env" "file" "exec" "store" ];
        };
        id = lib.mkOption {
          type = t.str;
        };
        provider = lib.mkOption {
          type = t.str;
        };
      }; }) ]));
        default = null;
      };
      password = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
        source = lib.mkOption {
          type = t.enum [ "env" "file" "exec" "store" ];
        };
        id = lib.mkOption {
          type = t.str;
        };
        provider = lib.mkOption {
          type = t.str;
        };
      }; }) ]);
        default = null;
      };
      remotePort = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      sshHostKeyPolicy = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.enum [ "strict" ]) (t.enum [ "openssh" ]) ]);
        default = null;
      };
      sshIdentity = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      sshTarget = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      tlsFingerprint = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      token = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
        source = lib.mkOption {
          type = t.enum [ "env" "file" "exec" "store" ];
        };
        id = lib.mkOption {
          type = t.str;
        };
        provider = lib.mkOption {
          type = t.str;
        };
      }; }) ]);
        default = null;
      };
      transport = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.enum [ "ssh" ]) (t.enum [ "direct" ]) ]);
        default = null;
      };
      url = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
    }; });
      default = null;
    };
    roles = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      assignments = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        byGithubLogin = lib.mkOption {
          type = t.nullOr (t.attrsOf (t.str));
          default = null;
        };
      }; });
        default = null;
      };
      default = lib.mkOption {
        type = t.str;
      };
      definitions = lib.mkOption {
        type = t.attrsOf (t.submodule { options = {
        accessPolicyPlugin = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        agents = lib.mkOption {
          type = t.oneOf [ (t.enum [ "*" ]) (t.anything) ];
        };
        modelPolicy = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          allow = lib.mkOption {
            type = t.nullOr (t.listOf (t.str));
            default = null;
          };
          deny = lib.mkOption {
            type = t.nullOr (t.listOf (t.str));
            default = null;
          };
          sourceAgent = lib.mkOption {
            type = t.nullOr (t.anything);
            default = null;
          };
        }; });
          default = null;
        };
        sandbox = lib.mkOption {
          type = t.nullOr (t.enum [ "inherit" "required" ]);
          default = null;
        };
        scopes = lib.mkOption {
          type = t.anything;
        };
        sessions = lib.mkOption {
          type = t.submodule { options = {
          others = lib.mkOption {
            type = t.enum [ "none" "view" "suggest" "write" ];
          };
        }; };
        };
      }; });
      };
    }; });
      default = null;
    };
    tailscale = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      mode = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.enum [ "off" ]) (t.enum [ "serve" ]) (t.enum [ "funnel" ]) ]);
        default = null;
      };
      preserveFunnel = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
    }; });
      default = null;
    };
    terminal = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      detachedSessionTimeoutSeconds = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      enabled = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      shell = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
    }; });
      default = null;
    };
    tls = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      autoGenerate = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      caPath = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      certPath = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      enabled = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      keyPath = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
    }; });
      default = null;
    };
    tools = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      allow = lib.mkOption {
        type = t.nullOr (t.listOf (t.str));
        default = null;
      };
      deny = lib.mkOption {
        type = t.nullOr (t.listOf (t.str));
        default = null;
      };
    }; });
      default = null;
    };
    trustedProxies = lib.mkOption {
      type = t.nullOr (t.listOf (t.str));
      default = null;
    };
    uploads = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      enabled = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
    }; });
      default = null;
    };
  }; });
    default = null;
  };

  hooks = lib.mkOption {
    type = t.nullOr (t.submodule { options = {
    allowRequestSessionKey = lib.mkOption {
      type = t.nullOr (t.bool);
      default = null;
    };
    allowedAgentIds = lib.mkOption {
      type = t.nullOr (t.listOf (t.str));
      default = null;
    };
    allowedSessionKeyPrefixes = lib.mkOption {
      type = t.nullOr (t.listOf (t.str));
      default = null;
    };
    defaultSessionKey = lib.mkOption {
      type = t.nullOr (t.str);
      default = null;
    };
    enabled = lib.mkOption {
      type = t.nullOr (t.bool);
      default = null;
    };
    gmail = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      account = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      allowUnsafeExternalContent = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      hookUrl = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      includeBody = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      label = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      maxBytes = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      model = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      pushToken = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      renewEveryMinutes = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      serve = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        bind = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        path = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        port = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
      }; });
        default = null;
      };
      subscription = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      tailscale = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        mode = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.enum [ "off" ]) (t.enum [ "serve" ]) (t.enum [ "funnel" ]) ]);
          default = null;
        };
        path = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        target = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
      }; });
        default = null;
      };
      thinking = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.enum [ "off" ]) (t.enum [ "minimal" ]) (t.enum [ "low" ]) (t.enum [ "medium" ]) (t.enum [ "high" ]) ]);
        default = null;
      };
      topic = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
    }; });
      default = null;
    };
    internal = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      enabled = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      entries = lib.mkOption {
        type = t.nullOr (t.attrsOf (t.submodule { options = {
        enabled = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
        env = lib.mkOption {
          type = t.nullOr (t.attrsOf (t.str));
          default = null;
        };
      }; }));
        default = null;
      };
      load = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        extraDirs = lib.mkOption {
          type = t.nullOr (t.listOf (t.str));
          default = null;
        };
      }; });
        default = null;
      };
    }; });
      default = null;
    };
    mappings = lib.mkOption {
      type = t.nullOr (t.listOf (t.submodule { options = {
      action = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.enum [ "wake" ]) (t.enum [ "agent" ]) ]);
        default = null;
      };
      agentId = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      allowUnsafeExternalContent = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      channel = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      deliver = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      forEach = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      id = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      match = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        path = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        source = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
      }; });
        default = null;
      };
      messageTemplate = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      model = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      name = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      sessionKey = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      sessionMode = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.enum [ "isolated" ]) (t.enum [ "persistent" ]) ]);
        default = null;
      };
      textTemplate = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      thinking = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      timeoutSeconds = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      to = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      transform = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        export = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        module = lib.mkOption {
          type = t.str;
        };
      }; });
        default = null;
      };
      wakeMode = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.enum [ "now" ]) (t.enum [ "next-heartbeat" ]) ]);
        default = null;
      };
    }; }));
      default = null;
    };
    path = lib.mkOption {
      type = t.nullOr (t.str);
      default = null;
    };
    presets = lib.mkOption {
      type = t.nullOr (t.listOf (t.str));
      default = null;
    };
    token = lib.mkOption {
      type = t.nullOr (t.str);
      default = null;
    };
    transformsDir = lib.mkOption {
      type = t.nullOr (t.str);
      default = null;
    };
  }; });
    default = null;
  };

  logging = lib.mkOption {
    type = t.nullOr (t.submodule { options = {
    audit = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      enabled = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      executionIdentity = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      messages = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.enum [ "off" ]) (t.enum [ "direct" ]) (t.enum [ "all" ]) ]);
        default = null;
      };
    }; });
      default = null;
    };
    consoleLevel = lib.mkOption {
      type = t.nullOr (t.oneOf [ (t.enum [ "silent" ]) (t.enum [ "fatal" ]) (t.enum [ "error" ]) (t.enum [ "warn" ]) (t.enum [ "info" ]) (t.enum [ "debug" ]) (t.enum [ "trace" ]) ]);
      default = null;
    };
    consoleStyle = lib.mkOption {
      type = t.nullOr (t.oneOf [ (t.enum [ "pretty" ]) (t.enum [ "json" ]) ]);
      default = null;
    };
    file = lib.mkOption {
      type = t.nullOr (t.str);
      default = null;
    };
    level = lib.mkOption {
      type = t.nullOr (t.oneOf [ (t.enum [ "silent" ]) (t.enum [ "fatal" ]) (t.enum [ "error" ]) (t.enum [ "warn" ]) (t.enum [ "info" ]) (t.enum [ "debug" ]) (t.enum [ "trace" ]) ]);
      default = null;
    };
    maxFileBytes = lib.mkOption {
      type = t.nullOr (t.int);
      default = null;
    };
    redactPatterns = lib.mkOption {
      type = t.nullOr (t.listOf (t.str));
      default = null;
    };
  }; });
    default = null;
  };

  mcp = lib.mkOption {
    type = t.nullOr (t.submodule { options = {
    apps = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      enabled = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      sandboxOrigin = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      sandboxPort = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
    }; });
      default = null;
    };
    servers = lib.mkOption {
      type = t.nullOr (t.attrsOf (t.submodule { options = {
      args = lib.mkOption {
        type = t.nullOr (t.listOf (t.str));
        default = null;
      };
      auth = lib.mkOption {
        type = t.nullOr (t.enum [ "oauth" ]);
        default = null;
      };
      clientCert = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      clientKey = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      codex = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        agents = lib.mkOption {
          type = t.nullOr (t.listOf (t.str));
          default = null;
        };
        defaultToolsApprovalMode = lib.mkOption {
          type = t.nullOr (t.enum [ "auto" "prompt" "approve" ]);
          default = null;
        };
      }; });
        default = null;
      };
      command = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      connectionTimeoutMs = lib.mkOption {
        type = t.nullOr (t.number);
        default = null;
      };
      cwd = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      enabled = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      env = lib.mkOption {
        type = t.nullOr (t.attrsOf (t.oneOf [ (t.str) (t.number) (t.bool) ]));
        default = null;
      };
      headers = lib.mkOption {
        type = t.nullOr (t.attrsOf (t.oneOf [ (t.str) (t.number) (t.bool) ]));
        default = null;
      };
      oauth = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        authProfileId = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        clientMetadataUrl = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        identity = lib.mkOption {
          type = t.nullOr (t.enum [ "shared" "per-requester" ]);
          default = null;
        };
        redirectUrl = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        scope = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
      }; });
        default = null;
      };
      requestTimeoutMs = lib.mkOption {
        type = t.nullOr (t.number);
        default = null;
      };
      sslVerify = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      supportsParallelToolCalls = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      toolFilter = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        exclude = lib.mkOption {
          type = t.nullOr (t.listOf (t.str));
          default = null;
        };
        include = lib.mkOption {
          type = t.nullOr (t.listOf (t.str));
          default = null;
        };
      }; });
        default = null;
      };
      transport = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.enum [ "stdio" ]) (t.enum [ "sse" ]) (t.enum [ "streamable-http" ]) ]);
        default = null;
      };
      url = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
    }; }));
      default = null;
    };
    sessionIdleTtlMs = lib.mkOption {
      type = t.nullOr (t.number);
      default = null;
    };
  }; });
    default = null;
  };

  memory = lib.mkOption {
    type = t.nullOr (t.submodule { options = {
    citations = lib.mkOption {
      type = t.nullOr (t.oneOf [ (t.enum [ "auto" ]) (t.enum [ "on" ]) (t.enum [ "off" ]) ]);
      default = null;
    };
    search = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      cache = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        enabled = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
      }; });
        default = null;
      };
      documentInputType = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      enabled = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      experimental = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        sessionMemory = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
      }; });
        default = null;
      };
      extraPaths = lib.mkOption {
        type = t.nullOr (t.listOf (t.oneOf [ (t.str) (t.submodule { options = {
        path = lib.mkOption {
          type = t.str;
        };
        pattern = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
      }; }) ]));
        default = null;
      };
      fallback = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      inputType = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      local = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        modelPath = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
      }; });
        default = null;
      };
      model = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      multimodal = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        enabled = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
        maxFileBytes = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        modalities = lib.mkOption {
          type = t.nullOr (t.listOf (t.oneOf [ (t.enum [ "image" ]) (t.enum [ "audio" ]) (t.enum [ "all" ]) ]));
          default = null;
        };
      }; });
        default = null;
      };
      outputDimensionality = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      provider = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      query = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        maxResults = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        minScore = lib.mkOption {
          type = t.nullOr (t.number);
          default = null;
        };
      }; });
        default = null;
      };
      queryInputType = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      rememberAcrossConversations = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      remote = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        apiKey = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
          source = lib.mkOption {
            type = t.enum [ "env" "file" "exec" "store" ];
          };
          id = lib.mkOption {
            type = t.str;
          };
          provider = lib.mkOption {
            type = t.str;
          };
        }; }) ]);
          default = null;
        };
        baseUrl = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        batch = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          enabled = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
        }; });
          default = null;
        };
        headers = lib.mkOption {
          type = t.nullOr (t.attrsOf (t.str));
          default = null;
        };
      }; });
        default = null;
      };
      sources = lib.mkOption {
        type = t.nullOr (t.listOf (t.oneOf [ (t.enum [ "memory" ]) (t.enum [ "sessions" ]) ]));
        default = null;
      };
      store = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        fts = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          tokenizer = lib.mkOption {
            type = t.nullOr (t.oneOf [ (t.enum [ "unicode61" ]) (t.enum [ "trigram" ]) ]);
            default = null;
          };
        }; });
          default = null;
        };
        vector = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          enabled = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          extensionPath = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
        }; });
          default = null;
        };
      }; });
        default = null;
      };
    }; });
      default = null;
    };
  }; });
    default = null;
  };

  messages = lib.mkOption {
    type = t.nullOr (t.submodule { options = {
    ackReaction = lib.mkOption {
      type = t.nullOr (t.str);
      default = null;
    };
    ackReactionScope = lib.mkOption {
      type = t.nullOr (t.enum [ "group-mentions" "group-all" "direct" "all" "off" "none" ]);
      default = null;
    };
    groupChat = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      historyLimit = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      mentionPatterns = lib.mkOption {
        type = t.nullOr (t.listOf (t.str));
        default = null;
      };
      unmentionedInbound = lib.mkOption {
        type = t.nullOr (t.enum [ "user_request" "room_event" ]);
        default = null;
      };
      visibleReplies = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.enum [ "automatic" "message_tool" ]) (t.bool) ]);
        default = null;
      };
    }; });
      default = null;
    };
    inbound = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      byChannel = lib.mkOption {
        type = t.nullOr (t.attrsOf (t.int));
        default = null;
      };
      debounceMs = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
    }; });
      default = null;
    };
    queue = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      allowCollaborativeSteering = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      byChannel = lib.mkOption {
        type = t.nullOr (t.attrsOf (t.oneOf [ (t.enum [ "steer" ]) (t.enum [ "followup" ]) (t.enum [ "collect" ]) (t.enum [ "interrupt" ]) ]));
        default = null;
      };
      cap = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      collaborativeSteeringFallback = lib.mkOption {
        type = t.nullOr (t.enum [ "queue" "reject" ]);
        default = null;
      };
      debounceMsByChannel = lib.mkOption {
        type = t.nullOr (t.attrsOf (t.int));
        default = null;
      };
      drop = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.enum [ "old" ]) (t.enum [ "new" ]) (t.enum [ "summarize" ]) ]);
        default = null;
      };
      mode = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.enum [ "steer" ]) (t.enum [ "followup" ]) (t.enum [ "collect" ]) (t.enum [ "interrupt" ]) ]);
        default = null;
      };
    }; });
      default = null;
    };
    responsePrefix = lib.mkOption {
      type = t.nullOr (t.str);
      default = null;
    };
    responseUsage = lib.mkOption {
      type = t.nullOr (t.oneOf [ (t.enum [ "on" "off" "tokens" "full" ]) (t.attrsOf (t.enum [ "on" "off" "tokens" "full" ])) ]);
      default = null;
    };
    statusReactions = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      enabled = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
    }; });
      default = null;
    };
    usageTemplate = lib.mkOption {
      type = t.nullOr (t.oneOf [ (t.str) (t.attrsOf (t.anything)) ]);
      default = null;
    };
    visibleReplies = lib.mkOption {
      type = t.nullOr (t.oneOf [ (t.enum [ "automatic" "message_tool" ]) (t.bool) ]);
      default = null;
    };
  }; });
    default = null;
  };

  meta = lib.mkOption {
    type = t.nullOr (t.submodule { options = {
    lastTouchedVersion = lib.mkOption {
      type = t.nullOr (t.str);
      default = null;
    };
    migrations = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      modelPolicyAllowlist = lib.mkOption {
        type = t.nullOr (t.enum [ true ]);
        default = null;
      };
      utilityModelSeparation = lib.mkOption {
        type = t.nullOr (t.enum [ true ]);
        default = null;
      };
      webhookListeners = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.enum [ true ]) (t.attrsOf (t.listOf (t.listOf (t.str)))) ]);
        default = null;
      };
    }; });
      default = null;
    };
  }; });
    default = null;
  };

  models = lib.mkOption {
    type = t.nullOr (t.submodule { options = {
    catalogRefresh = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      enabled = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      url = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
    }; });
      default = null;
    };
    mode = lib.mkOption {
      type = t.nullOr (t.oneOf [ (t.enum [ "merge" ]) (t.enum [ "replace" ]) ]);
      default = null;
    };
    providers = lib.mkOption {
      type = t.nullOr (t.attrsOf (t.submodule { options = {
      agentRuntime = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        id = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
      }; });
        default = null;
      };
      api = lib.mkOption {
        type = t.nullOr (t.enum [ "openai-completions" "openai-responses" "openai-chatgpt-responses" "anthropic-messages" "google-generative-ai" "google-interactions" "google-vertex" "github-copilot" "bedrock-converse-stream" "ollama" "pi-messages" "azure-openai-responses" ]);
        default = null;
      };
      apiKey = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
        source = lib.mkOption {
          type = t.enum [ "env" "file" "exec" "store" ];
        };
        id = lib.mkOption {
          type = t.str;
        };
        provider = lib.mkOption {
          type = t.str;
        };
      }; }) ]);
        default = null;
      };
      auth = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.enum [ "api-key" ]) (t.enum [ "aws-sdk" ]) (t.enum [ "oauth" ]) (t.enum [ "token" ]) ]);
        default = null;
      };
      authHeader = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      baseUrl = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      headers = lib.mkOption {
        type = t.nullOr (t.attrsOf (t.oneOf [ (t.str) (t.submodule { options = {
        source = lib.mkOption {
          type = t.enum [ "env" "file" "exec" "store" ];
        };
        id = lib.mkOption {
          type = t.str;
        };
        provider = lib.mkOption {
          type = t.str;
        };
      }; }) ]));
        default = null;
      };
      injectNumCtxForOpenAICompat = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      localService = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        args = lib.mkOption {
          type = t.nullOr (t.listOf (t.str));
          default = null;
        };
        command = lib.mkOption {
          type = t.str;
        };
        cwd = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        env = lib.mkOption {
          type = t.nullOr (t.attrsOf (t.str));
          default = null;
        };
        healthUrl = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        idleStopMs = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        readyTimeoutMs = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
      }; });
        default = null;
      };
      maxTokens = lib.mkOption {
        type = t.nullOr (t.number);
        default = null;
      };
      models = lib.mkOption {
        type = t.nullOr (t.listOf (t.submodule { options = {
        agentRuntime = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          id = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
        }; });
          default = null;
        };
        api = lib.mkOption {
          type = t.nullOr (t.enum [ "openai-completions" "openai-responses" "openai-chatgpt-responses" "anthropic-messages" "google-generative-ai" "google-interactions" "google-vertex" "github-copilot" "bedrock-converse-stream" "ollama" "pi-messages" "azure-openai-responses" ]);
          default = null;
        };
        baseUrl = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        compat = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          cacheControlFormat = lib.mkOption {
            type = t.nullOr (t.enum [ "anthropic" ]);
            default = null;
          };
          codeMode = lib.mkOption {
            type = t.nullOr (t.enum [ "preferred" "capable" ]);
            default = null;
          };
          defaultThinkingLevel = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          maxTokensField = lib.mkOption {
            type = t.nullOr (t.oneOf [ (t.enum [ "max_completion_tokens" ]) (t.enum [ "max_tokens" ]) ]);
            default = null;
          };
          openRouterRouting = lib.mkOption {
            type = t.nullOr (t.submodule { options = {
            allow_fallbacks = lib.mkOption {
              type = t.nullOr (t.bool);
              default = null;
            };
            data_collection = lib.mkOption {
              type = t.nullOr (t.enum [ "deny" "allow" ]);
              default = null;
            };
            enforce_distillable_text = lib.mkOption {
              type = t.nullOr (t.bool);
              default = null;
            };
            ignore = lib.mkOption {
              type = t.nullOr (t.listOf (t.str));
              default = null;
            };
            max_price = lib.mkOption {
              type = t.nullOr (t.submodule { options = {
              audio = lib.mkOption {
                type = t.nullOr (t.oneOf [ (t.number) (t.str) ]);
                default = null;
              };
              completion = lib.mkOption {
                type = t.nullOr (t.oneOf [ (t.number) (t.str) ]);
                default = null;
              };
              image = lib.mkOption {
                type = t.nullOr (t.oneOf [ (t.number) (t.str) ]);
                default = null;
              };
              prompt = lib.mkOption {
                type = t.nullOr (t.oneOf [ (t.number) (t.str) ]);
                default = null;
              };
              request = lib.mkOption {
                type = t.nullOr (t.oneOf [ (t.number) (t.str) ]);
                default = null;
              };
            }; });
              default = null;
            };
            only = lib.mkOption {
              type = t.nullOr (t.listOf (t.str));
              default = null;
            };
            order = lib.mkOption {
              type = t.nullOr (t.listOf (t.str));
              default = null;
            };
            preferred_max_latency = lib.mkOption {
              type = t.nullOr (t.oneOf [ (t.number) (t.submodule { options = {
              p50 = lib.mkOption {
                type = t.nullOr (t.number);
                default = null;
              };
              p75 = lib.mkOption {
                type = t.nullOr (t.number);
                default = null;
              };
              p90 = lib.mkOption {
                type = t.nullOr (t.number);
                default = null;
              };
              p99 = lib.mkOption {
                type = t.nullOr (t.number);
                default = null;
              };
            }; }) ]);
              default = null;
            };
            preferred_min_throughput = lib.mkOption {
              type = t.nullOr (t.oneOf [ (t.number) (t.submodule { options = {
              p50 = lib.mkOption {
                type = t.nullOr (t.number);
                default = null;
              };
              p75 = lib.mkOption {
                type = t.nullOr (t.number);
                default = null;
              };
              p90 = lib.mkOption {
                type = t.nullOr (t.number);
                default = null;
              };
              p99 = lib.mkOption {
                type = t.nullOr (t.number);
                default = null;
              };
            }; }) ]);
              default = null;
            };
            quantizations = lib.mkOption {
              type = t.nullOr (t.listOf (t.str));
              default = null;
            };
            require_parameters = lib.mkOption {
              type = t.nullOr (t.bool);
              default = null;
            };
            sort = lib.mkOption {
              type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
              by = lib.mkOption {
                type = t.nullOr (t.str);
                default = null;
              };
              partition = lib.mkOption {
                type = t.nullOr (t.str);
                default = null;
              };
            }; }) ]);
              default = null;
            };
            zdr = lib.mkOption {
              type = t.nullOr (t.bool);
              default = null;
            };
          }; });
            default = null;
          };
          reasoningEffortMap = lib.mkOption {
            type = t.nullOr (t.attrsOf (t.str));
            default = null;
          };
          requiresAssistantAfterToolResult = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          requiresOpenAiAnthropicToolPayload = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          requiresReasoningContentOnAssistantMessages = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          requiresStringContent = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          requiresThinkingAsText = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          requiresToolResultName = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          sendSessionAffinityHeaders = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          sendSessionIdHeader = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          strictMessageKeys = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          supportedReasoningEfforts = lib.mkOption {
            type = t.nullOr (t.listOf (t.str));
            default = null;
          };
          supportsDeveloperRole = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          supportsEagerToolInputStreaming = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          supportsInstructions = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          supportsJsonSchemaResponseFormat = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          supportsLongCacheRetention = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          supportsPromptCacheKey = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          supportsReasoningEffort = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          supportsResponsesContinuation = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          supportsStore = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          supportsStrictMode = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          supportsTemperature = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          supportsTools = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          supportsUsageInStreaming = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          thinkingFormat = lib.mkOption {
            type = t.nullOr (t.enum [ "openai" "openrouter" "deepseek" "together" "qwen" "qwen-chat-template" "zai" ]);
            default = null;
          };
          toolCallArgumentsEncoding = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          toolSchemaProfile = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          unsupportedToolSchemaKeywords = lib.mkOption {
            type = t.nullOr (t.listOf (t.str));
            default = null;
          };
          vercelGatewayRouting = lib.mkOption {
            type = t.nullOr (t.submodule { options = {
            only = lib.mkOption {
              type = t.nullOr (t.listOf (t.str));
              default = null;
            };
            order = lib.mkOption {
              type = t.nullOr (t.listOf (t.str));
              default = null;
            };
          }; });
            default = null;
          };
          visibleReasoningDetailTypes = lib.mkOption {
            type = t.nullOr (t.listOf (t.str));
            default = null;
          };
          zaiToolStream = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
        }; });
          default = null;
        };
        contextTokens = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        contextWindow = lib.mkOption {
          type = t.nullOr (t.number);
          default = null;
        };
        cost = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          cacheRead = lib.mkOption {
            type = t.nullOr (t.number);
            default = null;
          };
          cacheWrite = lib.mkOption {
            type = t.nullOr (t.number);
            default = null;
          };
          input = lib.mkOption {
            type = t.nullOr (t.number);
            default = null;
          };
          output = lib.mkOption {
            type = t.nullOr (t.number);
            default = null;
          };
          tieredPricing = lib.mkOption {
            type = t.nullOr (t.listOf (t.submodule { options = {
            cacheRead = lib.mkOption {
              type = t.number;
            };
            cacheWrite = lib.mkOption {
              type = t.number;
            };
            input = lib.mkOption {
              type = t.number;
            };
            output = lib.mkOption {
              type = t.number;
            };
            range = lib.mkOption {
              type = t.listOf (t.anything);
            };
          }; }));
            default = null;
          };
        }; });
          default = null;
        };
        headers = lib.mkOption {
          type = t.nullOr (t.attrsOf (t.str));
          default = null;
        };
        id = lib.mkOption {
          type = t.str;
        };
        input = lib.mkOption {
          type = t.nullOr (t.listOf (t.oneOf [ (t.enum [ "text" ]) (t.enum [ "image" ]) (t.enum [ "video" ]) (t.enum [ "audio" ]) ]));
          default = null;
        };
        maxTokens = lib.mkOption {
          type = t.nullOr (t.number);
          default = null;
        };
        mediaInput = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          image = lib.mkOption {
            type = t.nullOr (t.submodule { options = {
            maxBytes = lib.mkOption {
              type = t.nullOr (t.int);
              default = null;
            };
            maxPixels = lib.mkOption {
              type = t.nullOr (t.int);
              default = null;
            };
            maxSidePx = lib.mkOption {
              type = t.nullOr (t.int);
              default = null;
            };
            preferredSidePx = lib.mkOption {
              type = t.nullOr (t.int);
              default = null;
            };
            tokenMode = lib.mkOption {
              type = t.nullOr (t.oneOf [ (t.enum [ "tile" ]) (t.enum [ "detail" ]) (t.enum [ "provider" ]) ]);
              default = null;
            };
          }; });
            default = null;
          };
        }; });
          default = null;
        };
        metadataSource = lib.mkOption {
          type = t.nullOr (t.enum [ "models-add" ]);
          default = null;
        };
        name = lib.mkOption {
          type = t.str;
        };
        params = lib.mkOption {
          type = t.nullOr (t.attrsOf (t.anything));
          default = null;
        };
        reasoning = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
        responseModelEquivalent = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
        thinkingLevelMap = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          high = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          low = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          max = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          medium = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          minimal = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          off = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          xhigh = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
        }; });
          default = null;
        };
      }; }));
        default = null;
      };
      params = lib.mkOption {
        type = t.nullOr (t.attrsOf (t.anything));
        default = null;
      };
      region = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      request = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        allowPrivateNetwork = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
        auth = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.submodule { options = {
          mode = lib.mkOption {
            type = t.enum [ "provider-default" ];
          };
        }; }) (t.submodule { options = {
          mode = lib.mkOption {
            type = t.enum [ "authorization-bearer" ];
          };
          token = lib.mkOption {
            type = t.oneOf [ (t.str) (t.submodule { options = {
            source = lib.mkOption {
              type = t.enum [ "env" "file" "exec" "store" ];
            };
            id = lib.mkOption {
              type = t.str;
            };
            provider = lib.mkOption {
              type = t.str;
            };
          }; }) ];
          };
        }; }) (t.submodule { options = {
          headerName = lib.mkOption {
            type = t.str;
          };
          mode = lib.mkOption {
            type = t.enum [ "header" ];
          };
          prefix = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          value = lib.mkOption {
            type = t.oneOf [ (t.str) (t.submodule { options = {
            source = lib.mkOption {
              type = t.enum [ "env" "file" "exec" "store" ];
            };
            id = lib.mkOption {
              type = t.str;
            };
            provider = lib.mkOption {
              type = t.str;
            };
          }; }) ];
          };
        }; }) ]);
          default = null;
        };
        headers = lib.mkOption {
          type = t.nullOr (t.attrsOf (t.oneOf [ (t.str) (t.submodule { options = {
          source = lib.mkOption {
            type = t.enum [ "env" "file" "exec" "store" ];
          };
          id = lib.mkOption {
            type = t.str;
          };
          provider = lib.mkOption {
            type = t.str;
          };
        }; }) ]));
          default = null;
        };
        proxy = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.submodule { options = {
          mode = lib.mkOption {
            type = t.enum [ "env-proxy" ];
          };
          tls = lib.mkOption {
            type = t.nullOr (t.submodule { options = {
            ca = lib.mkOption {
              type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
              source = lib.mkOption {
                type = t.enum [ "env" "file" "exec" "store" ];
              };
              id = lib.mkOption {
                type = t.str;
              };
              provider = lib.mkOption {
                type = t.str;
              };
            }; }) ]);
              default = null;
            };
            cert = lib.mkOption {
              type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
              source = lib.mkOption {
                type = t.enum [ "env" "file" "exec" "store" ];
              };
              id = lib.mkOption {
                type = t.str;
              };
              provider = lib.mkOption {
                type = t.str;
              };
            }; }) ]);
              default = null;
            };
            insecureSkipVerify = lib.mkOption {
              type = t.nullOr (t.bool);
              default = null;
            };
            key = lib.mkOption {
              type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
              source = lib.mkOption {
                type = t.enum [ "env" "file" "exec" "store" ];
              };
              id = lib.mkOption {
                type = t.str;
              };
              provider = lib.mkOption {
                type = t.str;
              };
            }; }) ]);
              default = null;
            };
            passphrase = lib.mkOption {
              type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
              source = lib.mkOption {
                type = t.enum [ "env" "file" "exec" "store" ];
              };
              id = lib.mkOption {
                type = t.str;
              };
              provider = lib.mkOption {
                type = t.str;
              };
            }; }) ]);
              default = null;
            };
            serverName = lib.mkOption {
              type = t.nullOr (t.str);
              default = null;
            };
          }; });
            default = null;
          };
        }; }) (t.submodule { options = {
          mode = lib.mkOption {
            type = t.enum [ "explicit-proxy" ];
          };
          tls = lib.mkOption {
            type = t.nullOr (t.submodule { options = {
            ca = lib.mkOption {
              type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
              source = lib.mkOption {
                type = t.enum [ "env" "file" "exec" "store" ];
              };
              id = lib.mkOption {
                type = t.str;
              };
              provider = lib.mkOption {
                type = t.str;
              };
            }; }) ]);
              default = null;
            };
            cert = lib.mkOption {
              type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
              source = lib.mkOption {
                type = t.enum [ "env" "file" "exec" "store" ];
              };
              id = lib.mkOption {
                type = t.str;
              };
              provider = lib.mkOption {
                type = t.str;
              };
            }; }) ]);
              default = null;
            };
            insecureSkipVerify = lib.mkOption {
              type = t.nullOr (t.bool);
              default = null;
            };
            key = lib.mkOption {
              type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
              source = lib.mkOption {
                type = t.enum [ "env" "file" "exec" "store" ];
              };
              id = lib.mkOption {
                type = t.str;
              };
              provider = lib.mkOption {
                type = t.str;
              };
            }; }) ]);
              default = null;
            };
            passphrase = lib.mkOption {
              type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
              source = lib.mkOption {
                type = t.enum [ "env" "file" "exec" "store" ];
              };
              id = lib.mkOption {
                type = t.str;
              };
              provider = lib.mkOption {
                type = t.str;
              };
            }; }) ]);
              default = null;
            };
            serverName = lib.mkOption {
              type = t.nullOr (t.str);
              default = null;
            };
          }; });
            default = null;
          };
          url = lib.mkOption {
            type = t.str;
          };
        }; }) ]);
          default = null;
        };
        tls = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          ca = lib.mkOption {
            type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
            source = lib.mkOption {
              type = t.enum [ "env" "file" "exec" "store" ];
            };
            id = lib.mkOption {
              type = t.str;
            };
            provider = lib.mkOption {
              type = t.str;
            };
          }; }) ]);
            default = null;
          };
          cert = lib.mkOption {
            type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
            source = lib.mkOption {
              type = t.enum [ "env" "file" "exec" "store" ];
            };
            id = lib.mkOption {
              type = t.str;
            };
            provider = lib.mkOption {
              type = t.str;
            };
          }; }) ]);
            default = null;
          };
          insecureSkipVerify = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          key = lib.mkOption {
            type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
            source = lib.mkOption {
              type = t.enum [ "env" "file" "exec" "store" ];
            };
            id = lib.mkOption {
              type = t.str;
            };
            provider = lib.mkOption {
              type = t.str;
            };
          }; }) ]);
            default = null;
          };
          passphrase = lib.mkOption {
            type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
            source = lib.mkOption {
              type = t.enum [ "env" "file" "exec" "store" ];
            };
            id = lib.mkOption {
              type = t.str;
            };
            provider = lib.mkOption {
              type = t.str;
            };
          }; }) ]);
            default = null;
          };
          serverName = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
        }; });
          default = null;
        };
      }; });
        default = null;
      };
      timeoutSeconds = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
    }; }));
      default = null;
    };
  }; });
    default = null;
  };

  nodeHost = lib.mkOption {
    type = t.nullOr (t.submodule { options = {
    agentRuns = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      claude = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        enabled = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
      }; });
        default = null;
      };
    }; });
      default = null;
    };
    autoUpdate = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      enabled = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
    }; });
      default = null;
    };
    browserProxy = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      allowProfiles = lib.mkOption {
        type = t.nullOr (t.listOf (t.str));
        default = null;
      };
      enabled = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
    }; });
      default = null;
    };
    mcp = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      servers = lib.mkOption {
        type = t.nullOr (t.attrsOf (t.submodule { options = {
        args = lib.mkOption {
          type = t.nullOr (t.listOf (t.str));
          default = null;
        };
        auth = lib.mkOption {
          type = t.nullOr (t.enum [ "oauth" ]);
          default = null;
        };
        clientCert = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        clientKey = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        codex = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          agents = lib.mkOption {
            type = t.nullOr (t.listOf (t.str));
            default = null;
          };
          defaultToolsApprovalMode = lib.mkOption {
            type = t.nullOr (t.enum [ "auto" "prompt" "approve" ]);
            default = null;
          };
        }; });
          default = null;
        };
        command = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        connectionTimeoutMs = lib.mkOption {
          type = t.nullOr (t.number);
          default = null;
        };
        cwd = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        enabled = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
        env = lib.mkOption {
          type = t.nullOr (t.attrsOf (t.oneOf [ (t.str) (t.number) (t.bool) ]));
          default = null;
        };
        headers = lib.mkOption {
          type = t.nullOr (t.attrsOf (t.oneOf [ (t.str) (t.number) (t.bool) ]));
          default = null;
        };
        oauth = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          authProfileId = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          clientMetadataUrl = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          identity = lib.mkOption {
            type = t.nullOr (t.enum [ "shared" "per-requester" ]);
            default = null;
          };
          redirectUrl = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          scope = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
        }; });
          default = null;
        };
        requestTimeoutMs = lib.mkOption {
          type = t.nullOr (t.number);
          default = null;
        };
        sslVerify = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
        supportsParallelToolCalls = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
        toolFilter = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          exclude = lib.mkOption {
            type = t.nullOr (t.listOf (t.str));
            default = null;
          };
          include = lib.mkOption {
            type = t.nullOr (t.listOf (t.str));
            default = null;
          };
        }; });
          default = null;
        };
        transport = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.enum [ "stdio" ]) (t.enum [ "sse" ]) (t.enum [ "streamable-http" ]) ]);
          default = null;
        };
        url = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
      }; }));
        default = null;
      };
    }; });
      default = null;
    };
    skills = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      enabled = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
    }; });
      default = null;
    };
    workerRuns = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      capacity = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      containerImage = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      enabled = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      folders = lib.mkOption {
        type = t.nullOr (t.listOf (t.str));
        default = null;
      };
      isolation = lib.mkOption {
        type = t.nullOr (t.enum [ "none" "container" ]);
        default = null;
      };
    }; });
      default = null;
    };
  }; });
    default = null;
  };

  plugins = lib.mkOption {
    type = t.nullOr (t.submodule { options = {
    allow = lib.mkOption {
      type = t.nullOr (t.listOf (t.str));
      default = null;
    };
    deny = lib.mkOption {
      type = t.nullOr (t.listOf (t.str));
      default = null;
    };
    enabled = lib.mkOption {
      type = t.nullOr (t.bool);
      default = null;
    };
    entries = lib.mkOption {
      type = t.nullOr (t.attrsOf (t.submodule { options = {
      config = lib.mkOption {
        type = t.nullOr (t.attrsOf (t.anything));
        default = null;
      };
      enabled = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      hooks = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        allowConversationAccess = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
        allowPromptInjection = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
        timeoutMs = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        timeouts = lib.mkOption {
          type = t.nullOr (t.attrsOf (t.int));
          default = null;
        };
      }; });
        default = null;
      };
      llm = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        allowAgentIdOverride = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
        allowAuthProfileOverride = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
        allowModelOverride = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
        allowedCompletionModels = lib.mkOption {
          type = t.nullOr (t.listOf (t.str));
          default = null;
        };
        allowedModels = lib.mkOption {
          type = t.nullOr (t.listOf (t.str));
          default = null;
        };
      }; });
        default = null;
      };
      subagent = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        allowModelOverride = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
        allowedModels = lib.mkOption {
          type = t.nullOr (t.listOf (t.str));
          default = null;
        };
      }; });
        default = null;
      };
    }; }));
      default = null;
    };
    load = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      paths = lib.mkOption {
        type = t.nullOr (t.listOf (t.str));
        default = null;
      };
    }; });
      default = null;
    };
    slots = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      contextEngine = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      memory = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
    }; });
      default = null;
    };
  }; });
    default = null;
  };

  proxy = lib.mkOption {
    type = t.nullOr (t.submodule { options = {
    enabled = lib.mkOption {
      type = t.nullOr (t.bool);
      default = null;
    };
    loopbackMode = lib.mkOption {
      type = t.nullOr (t.enum [ "gateway-only" "proxy" "block" ]);
      default = null;
    };
    proxyUrl = lib.mkOption {
      type = t.nullOr (t.str);
      default = null;
    };
    tls = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      caFile = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
    }; });
      default = null;
    };
  }; });
    default = null;
  };

  secrets = lib.mkOption {
    type = t.nullOr (t.submodule { options = {
    defaults = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      env = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      exec = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      file = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      store = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
    }; });
      default = null;
    };
    egressProxy = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      allowedHosts = lib.mkOption {
        type = t.nullOr (t.listOf (t.str));
        default = null;
      };
      bypassHosts = lib.mkOption {
        type = t.nullOr (t.listOf (t.str));
        default = null;
      };
      enabled = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
    }; });
      default = null;
    };
    providers = lib.mkOption {
      type = t.nullOr (t.attrsOf (t.submodule { options = {
      source = lib.mkOption {
        type = t.enum [ "env" "file" "exec" "store" ];
      };
      allowlist = lib.mkOption {
        type = t.nullOr (t.listOf (t.str));
        default = null;
      };
      args = lib.mkOption {
        type = t.nullOr (t.listOf (t.str));
        default = null;
      };
      command = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      env = lib.mkOption {
        type = t.nullOr (t.attrsOf (t.str));
        default = null;
      };
      jsonOnly = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      maxBytes = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      maxOutputBytes = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      mode = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.enum [ "singleValue" ]) (t.enum [ "json" ]) ]);
        default = null;
      };
      noOutputTimeoutMs = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      passEnv = lib.mkOption {
        type = t.nullOr (t.listOf (t.str));
        default = null;
      };
      path = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      pluginIntegration = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        integrationId = lib.mkOption {
          type = t.str;
        };
        pluginId = lib.mkOption {
          type = t.str;
        };
      }; });
        default = null;
      };
      timeoutMs = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      trustedDirs = lib.mkOption {
        type = t.nullOr (t.listOf (t.str));
        default = null;
      };
    }; }));
      default = null;
    };
  }; });
    default = null;
  };

  security = lib.mkOption {
    type = t.nullOr (t.submodule { options = {
    audit = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      suppressions = lib.mkOption {
        type = t.nullOr (t.listOf (t.submodule { options = {
        checkId = lib.mkOption {
          type = t.str;
        };
        detailIncludes = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        reason = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        titleIncludes = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
      }; }));
        default = null;
      };
    }; });
      default = null;
    };
    installPolicy = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      enabled = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      exec = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        args = lib.mkOption {
          type = t.nullOr (t.listOf (t.str));
          default = null;
        };
        command = lib.mkOption {
          type = t.str;
        };
        env = lib.mkOption {
          type = t.nullOr (t.attrsOf (t.str));
          default = null;
        };
        maxOutputBytes = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        noOutputTimeoutMs = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        passEnv = lib.mkOption {
          type = t.nullOr (t.listOf (t.str));
          default = null;
        };
        source = lib.mkOption {
          type = t.enum [ "exec" ];
        };
        timeoutMs = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        trustedDirs = lib.mkOption {
          type = t.nullOr (t.listOf (t.str));
          default = null;
        };
      }; });
        default = null;
      };
      targets = lib.mkOption {
        type = t.nullOr (t.listOf (t.oneOf [ (t.enum [ "skill" ]) (t.enum [ "plugin" ]) ]));
        default = null;
      };
    }; });
      default = null;
    };
  }; });
    default = null;
  };

  session = lib.mkOption {
    type = t.nullOr (t.submodule { options = {
    communication = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      receive = lib.mkOption {
        type = t.nullOr (t.enum [ "always" "ask" "never" ]);
        default = null;
      };
      send = lib.mkOption {
        type = t.nullOr (t.enum [ "always" "ask" "never" ]);
        default = null;
      };
    }; });
      default = null;
    };
    dmScope = lib.mkOption {
      type = t.nullOr (t.enum [ "main" "per-peer" "per-channel-peer" "per-account-channel-peer" ]);
      default = null;
    };
    groupScope = lib.mkOption {
      type = t.nullOr (t.enum [ "main" "per-group" ]);
      default = null;
    };
    identityLinks = lib.mkOption {
      type = t.nullOr (t.attrsOf (t.listOf (t.str)));
      default = null;
    };
    mainKey = lib.mkOption {
      type = t.nullOr (t.str);
      default = null;
    };
    maintenance = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      archiveDashboardAfter = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.oneOf [ (t.str) (t.number) ]) (t.enum [ false ]) (t.enum [ 0 ]) ]);
        default = null;
      };
      coldStorage = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        afterDays = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        enabled = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
      }; });
        default = null;
      };
      highWaterBytes = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.str) (t.number) ]);
        default = null;
      };
      maxDiskBytes = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.str) (t.number) (t.enum [ false ]) ]);
        default = null;
      };
      maxEntries = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      mode = lib.mkOption {
        type = t.nullOr (t.enum [ "enforce" "warn" ]);
        default = null;
      };
      preserveRecent = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.oneOf [ (t.str) (t.number) ]) (t.enum [ false ]) ]);
        default = null;
      };
      pruneAfter = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.str) (t.number) ]);
        default = null;
      };
      resetArchiveRetention = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.oneOf [ (t.str) (t.number) ]) (t.enum [ false ]) ]);
        default = null;
      };
    }; });
      default = null;
    };
    notifyOnCreate = lib.mkOption {
      type = t.nullOr (t.bool);
      default = null;
    };
    reset = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      atHour = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      idleMinutes = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      mode = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.enum [ "none" ]) (t.enum [ "daily" ]) (t.enum [ "idle" ]) ]);
        default = null;
      };
    }; });
      default = null;
    };
    resetByChannel = lib.mkOption {
      type = t.nullOr (t.attrsOf (t.submodule { options = {
      atHour = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      idleMinutes = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      mode = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.enum [ "none" ]) (t.enum [ "daily" ]) (t.enum [ "idle" ]) ]);
        default = null;
      };
    }; }));
      default = null;
    };
    resetByType = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      direct = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        atHour = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        idleMinutes = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        mode = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.enum [ "none" ]) (t.enum [ "daily" ]) (t.enum [ "idle" ]) ]);
          default = null;
        };
      }; });
        default = null;
      };
      group = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        atHour = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        idleMinutes = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        mode = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.enum [ "none" ]) (t.enum [ "daily" ]) (t.enum [ "idle" ]) ]);
          default = null;
        };
      }; });
        default = null;
      };
      thread = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        atHour = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        idleMinutes = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        mode = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.enum [ "none" ]) (t.enum [ "daily" ]) (t.enum [ "idle" ]) ]);
          default = null;
        };
      }; });
        default = null;
      };
    }; });
      default = null;
    };
    resetTriggers = lib.mkOption {
      type = t.nullOr (t.listOf (t.str));
      default = null;
    };
    scope = lib.mkOption {
      type = t.nullOr (t.oneOf [ (t.enum [ "per-sender" ]) (t.enum [ "global" ]) ]);
      default = null;
    };
    sendPolicy = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      default = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.enum [ "allow" ]) (t.enum [ "deny" ]) ]);
        default = null;
      };
      rules = lib.mkOption {
        type = t.nullOr (t.listOf (t.submodule { options = {
        action = lib.mkOption {
          type = t.oneOf [ (t.enum [ "allow" ]) (t.enum [ "deny" ]) ];
        };
        match = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          channel = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          chatType = lib.mkOption {
            type = t.nullOr (t.oneOf [ (t.enum [ "direct" ]) (t.enum [ "group" ]) (t.enum [ "channel" ]) ]);
            default = null;
          };
          keyPrefix = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          rawKeyPrefix = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
        }; });
          default = null;
        };
      }; }));
        default = null;
      };
    }; });
      default = null;
    };
    sharing = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      drafts = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      readOnly = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      suggest = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
    }; });
      default = null;
    };
    store = lib.mkOption {
      type = t.nullOr (t.str);
      default = null;
    };
    threadBindings = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      defaultSpawnContext = lib.mkOption {
        type = t.nullOr (t.enum [ "isolated" "fork" ]);
        default = null;
      };
      enabled = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      idleHours = lib.mkOption {
        type = t.nullOr (t.number);
        default = null;
      };
      maxAgeHours = lib.mkOption {
        type = t.nullOr (t.number);
        default = null;
      };
      spawnSessions = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
    }; });
      default = null;
    };
  }; });
    default = null;
  };

  skills = lib.mkOption {
    type = t.nullOr (t.submodule { options = {
    allowBundled = lib.mkOption {
      type = t.nullOr (t.listOf (t.str));
      default = null;
    };
    entries = lib.mkOption {
      type = t.nullOr (t.attrsOf (t.submodule { options = {
      apiKey = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
        source = lib.mkOption {
          type = t.enum [ "env" "file" "exec" "store" ];
        };
        id = lib.mkOption {
          type = t.str;
        };
        provider = lib.mkOption {
          type = t.str;
        };
      }; }) ]);
        default = null;
      };
      config = lib.mkOption {
        type = t.nullOr (t.attrsOf (t.anything));
        default = null;
      };
      enabled = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      env = lib.mkOption {
        type = t.nullOr (t.attrsOf (t.str));
        default = null;
      };
    }; }));
      default = null;
    };
    install = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      allowUploadedArchives = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      nodeManager = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.enum [ "npm" ]) (t.enum [ "pnpm" ]) (t.enum [ "yarn" ]) (t.enum [ "bun" ]) ]);
        default = null;
      };
      preferBrew = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
    }; });
      default = null;
    };
    limits = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      maxCandidatesPerRoot = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      maxSkillFileBytes = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      maxSkillsInPrompt = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      maxSkillsLoadedPerSource = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      maxSkillsPromptChars = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
    }; });
      default = null;
    };
    load = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      allowSymlinkTargets = lib.mkOption {
        type = t.nullOr (t.listOf (t.str));
        default = null;
      };
      extraDirs = lib.mkOption {
        type = t.nullOr (t.listOf (t.str));
        default = null;
      };
      watch = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
    }; });
      default = null;
    };
    workshop = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      autonomous = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        channelNotices = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
        mode = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.enum [ "off" ]) (t.enum [ "auto" ]) ]);
          default = null;
        };
      }; });
        default = null;
      };
      maxSkillBytes = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
    }; });
      default = null;
    };
  }; });
    default = null;
  };

  storage = lib.mkOption {
    type = t.nullOr (t.submodule { options = {
    locations = lib.mkOption {
      type = t.nullOr (t.attrsOf (t.submodule { options = {
      encryption = lib.mkOption {
        type = t.oneOf [ (t.enum [ "none" ]) (t.submodule { options = {
        passphrase = lib.mkOption {
          type = t.oneOf [ (t.str) (t.submodule { options = {
          source = lib.mkOption {
            type = t.enum [ "env" "file" "exec" "store" ];
          };
          id = lib.mkOption {
            type = t.str;
          };
          provider = lib.mkOption {
            type = t.str;
          };
        }; }) ];
        };
      }; }) ];
      };
      provider = lib.mkOption {
        type = t.str;
      };
      settings = lib.mkOption {
        type = t.attrsOf (t.anything);
      };
    }; }));
      default = null;
    };
  }; });
    default = null;
  };

  surfaces = lib.mkOption {
    type = t.nullOr (t.attrsOf (t.submodule { options = {
    silentReply = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      group = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.enum [ "allow" ]) (t.enum [ "disallow" ]) ]);
        default = null;
      };
    }; });
      default = null;
    };
  }; }));
    default = null;
  };

  talk = lib.mkOption {
    type = t.nullOr (t.submodule { options = {
    agentId = lib.mkOption {
      type = t.nullOr (t.str);
      default = null;
    };
    consultFastMode = lib.mkOption {
      type = t.nullOr (t.bool);
      default = null;
    };
    consultThinkingLevel = lib.mkOption {
      type = t.nullOr (t.enum [ "off" "minimal" "low" "medium" "high" "xhigh" "adaptive" "max" "ultra" ]);
      default = null;
    };
    interruptOnSpeech = lib.mkOption {
      type = t.nullOr (t.bool);
      default = null;
    };
    provider = lib.mkOption {
      type = t.nullOr (t.str);
      default = null;
    };
    providers = lib.mkOption {
      type = t.nullOr (t.attrsOf (t.submodule { options = {
      apiKey = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
        source = lib.mkOption {
          type = t.enum [ "env" "file" "exec" "store" ];
        };
        id = lib.mkOption {
          type = t.str;
        };
        provider = lib.mkOption {
          type = t.str;
        };
      }; }) ]);
        default = null;
      };
    }; }));
      default = null;
    };
    realtime = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      brain = lib.mkOption {
        type = t.nullOr (t.enum [ "agent-consult" "direct-tools" "none" ]);
        default = null;
      };
      consultRouting = lib.mkOption {
        type = t.nullOr (t.enum [ "provider-direct" "force-agent-consult" ]);
        default = null;
      };
      instructions = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      mode = lib.mkOption {
        type = t.nullOr (t.enum [ "realtime" "stt-tts" "transcription" ]);
        default = null;
      };
      model = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      prefixPaddingMs = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      provider = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      providers = lib.mkOption {
        type = t.nullOr (t.attrsOf (t.submodule { options = {
        apiKey = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
          source = lib.mkOption {
            type = t.enum [ "env" "file" "exec" "store" ];
          };
          id = lib.mkOption {
            type = t.str;
          };
          provider = lib.mkOption {
            type = t.str;
          };
        }; }) ]);
          default = null;
        };
      }; }));
        default = null;
      };
      reasoningEffort = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      silenceDurationMs = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      speakerVoice = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      speakerVoiceId = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      transport = lib.mkOption {
        type = t.nullOr (t.enum [ "webrtc" "provider-websocket" "gateway-relay" "managed-room" ]);
        default = null;
      };
      vadThreshold = lib.mkOption {
        type = t.nullOr (t.number);
        default = null;
      };
    }; });
      default = null;
    };
    silenceTimeoutMs = lib.mkOption {
      type = t.nullOr (t.int);
      default = null;
    };
    speechLocale = lib.mkOption {
      type = t.nullOr (t.str);
      default = null;
    };
  }; });
    default = null;
  };

  telemetry = lib.mkOption {
    type = t.nullOr (t.submodule { options = {
    consentedAt = lib.mkOption {
      type = t.nullOr (t.str);
      default = null;
    };
    enabled = lib.mkOption {
      type = t.nullOr (t.bool);
      default = null;
    };
  }; });
    default = null;
  };

  tools = lib.mkOption {
    type = t.nullOr (t.submodule { options = {
    agentToAgent = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      allow = lib.mkOption {
        type = t.nullOr (t.listOf (t.str));
        default = null;
      };
      enabled = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
    }; });
      default = null;
    };
    allow = lib.mkOption {
      type = t.nullOr (t.listOf (t.str));
      default = null;
    };
    alsoAllow = lib.mkOption {
      type = t.nullOr (t.listOf (t.str));
      default = null;
    };
    byProvider = lib.mkOption {
      type = t.nullOr (t.attrsOf (t.submodule { options = {
      allow = lib.mkOption {
        type = t.nullOr (t.listOf (t.str));
        default = null;
      };
      alsoAllow = lib.mkOption {
        type = t.nullOr (t.listOf (t.str));
        default = null;
      };
      deny = lib.mkOption {
        type = t.nullOr (t.listOf (t.str));
        default = null;
      };
      profile = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.enum [ "minimal" ]) (t.enum [ "coding" ]) (t.enum [ "messaging" ]) (t.enum [ "full" ]) ]);
        default = null;
      };
    }; }));
      default = null;
    };
    codeMode = lib.mkOption {
      type = t.nullOr (t.oneOf [ (t.bool) (t.enum [ "auto" ]) (t.submodule { options = {
      enabled = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.bool) (t.enum [ "auto" ]) ]);
        default = null;
      };
      executor = lib.mkOption {
        type = t.nullOr (t.enum [ "node" "quickjs" ]);
        default = null;
      };
      maxOutputBytes = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      maxPendingToolCalls = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      maxSearchLimit = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      maxSnapshotBytes = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      memoryLimitBytes = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      mode = lib.mkOption {
        type = t.nullOr (t.enum [ "only" ]);
        default = null;
      };
      searchDefaultLimit = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      snapshotTtlSeconds = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      timeoutMs = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
    }; }) ]);
      default = null;
    };
    deny = lib.mkOption {
      type = t.nullOr (t.listOf (t.str));
      default = null;
    };
    elevated = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      allowFrom = lib.mkOption {
        type = t.nullOr (t.attrsOf (t.listOf (t.oneOf [ (t.str) (t.number) ])));
        default = null;
      };
      enabled = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
    }; });
      default = null;
    };
    exec = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      applyPatch = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        allowModels = lib.mkOption {
          type = t.nullOr (t.listOf (t.str));
          default = null;
        };
        enabled = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
        workspaceOnly = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
      }; });
        default = null;
      };
      approvalRunningNoticeMs = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      ask = lib.mkOption {
        type = t.nullOr (t.enum [ "off" "on-miss" "always" ]);
        default = null;
      };
      backgroundMs = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      cleanupMs = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      commandHighlighting = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      grantExpiryDays = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      host = lib.mkOption {
        type = t.nullOr (t.enum [ "auto" "sandbox" "gateway" "node" ]);
        default = null;
      };
      mode = lib.mkOption {
        type = t.nullOr (t.enum [ "deny" "allowlist" "ask" "auto" "full" ]);
        default = null;
      };
      node = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      notifyOnExit = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      notifyOnExitEmptySuccess = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      pathPrepend = lib.mkOption {
        type = t.nullOr (t.listOf (t.str));
        default = null;
      };
      reviewer = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        fastMode = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
        model = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
          fallbacks = lib.mkOption {
            type = t.nullOr (t.listOf (t.str));
            default = null;
          };
          primary = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
        }; }) ]);
          default = null;
        };
        thinking = lib.mkOption {
          type = t.nullOr (t.enum [ "minimal" "low" "medium" "high" "xhigh" "max" ]);
          default = null;
        };
        timeoutMs = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
      }; });
        default = null;
      };
      safeBinProfiles = lib.mkOption {
        type = t.nullOr (t.attrsOf (t.submodule { options = {
        allowedValueFlags = lib.mkOption {
          type = t.nullOr (t.listOf (t.str));
          default = null;
        };
        deniedFlags = lib.mkOption {
          type = t.nullOr (t.listOf (t.str));
          default = null;
        };
        maxPositional = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        minPositional = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
      }; }));
        default = null;
      };
      safeBinTrustedDirs = lib.mkOption {
        type = t.nullOr (t.listOf (t.str));
        default = null;
      };
      safeBins = lib.mkOption {
        type = t.nullOr (t.listOf (t.str));
        default = null;
      };
      security = lib.mkOption {
        type = t.nullOr (t.enum [ "deny" "allowlist" "full" ]);
        default = null;
      };
      strictInlineEval = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      timeoutSeconds = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
    }; });
      default = null;
    };
    fs = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      workspaceOnly = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
    }; });
      default = null;
    };
    github = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      gitAuthor = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        email = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        name = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
      }; });
        default = null;
      };
      kind = lib.mkOption {
        type = t.nullOr (t.enum [ "oauth" ]);
        default = null;
      };
      profileId = lib.mkOption {
        type = t.str;
      };
    }; });
      default = null;
    };
    links = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      enabled = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      maxLinks = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      models = lib.mkOption {
        type = t.nullOr (t.listOf (t.submodule { options = {
        args = lib.mkOption {
          type = t.nullOr (t.listOf (t.str));
          default = null;
        };
        command = lib.mkOption {
          type = t.str;
        };
        timeoutSeconds = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        type = lib.mkOption {
          type = t.nullOr (t.enum [ "cli" ]);
          default = null;
        };
      }; }));
        default = null;
      };
      scope = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        default = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.enum [ "allow" ]) (t.enum [ "deny" ]) ]);
          default = null;
        };
        rules = lib.mkOption {
          type = t.nullOr (t.listOf (t.submodule { options = {
          action = lib.mkOption {
            type = t.oneOf [ (t.enum [ "allow" ]) (t.enum [ "deny" ]) ];
          };
          match = lib.mkOption {
            type = t.nullOr (t.submodule { options = {
            channel = lib.mkOption {
              type = t.nullOr (t.str);
              default = null;
            };
            chatType = lib.mkOption {
              type = t.nullOr (t.oneOf [ (t.enum [ "direct" ]) (t.enum [ "group" ]) (t.enum [ "channel" ]) ]);
              default = null;
            };
            keyPrefix = lib.mkOption {
              type = t.nullOr (t.str);
              default = null;
            };
            rawKeyPrefix = lib.mkOption {
              type = t.nullOr (t.str);
              default = null;
            };
          }; });
            default = null;
          };
        }; }));
          default = null;
        };
      }; });
        default = null;
      };
      timeoutSeconds = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
    }; });
      default = null;
    };
    loopDetection = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      enabled = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
    }; });
      default = null;
    };
    media = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      audio = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        attachments = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          maxAttachments = lib.mkOption {
            type = t.nullOr (t.int);
            default = null;
          };
          mode = lib.mkOption {
            type = t.nullOr (t.oneOf [ (t.enum [ "first" ]) (t.enum [ "all" ]) ]);
            default = null;
          };
          prefer = lib.mkOption {
            type = t.nullOr (t.oneOf [ (t.enum [ "first" ]) (t.enum [ "last" ]) (t.enum [ "path" ]) (t.enum [ "url" ]) ]);
            default = null;
          };
        }; });
          default = null;
        };
        baseUrl = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        echoFormat = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        echoTranscript = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
        enabled = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
        headers = lib.mkOption {
          type = t.nullOr (t.attrsOf (t.str));
          default = null;
        };
        language = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        maxBytes = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        maxChars = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        preferredModel = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        prompt = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        providerOptions = lib.mkOption {
          type = t.nullOr (t.attrsOf (t.attrsOf (t.oneOf [ (t.str) (t.number) (t.bool) ])));
          default = null;
        };
        request = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          auth = lib.mkOption {
            type = t.nullOr (t.oneOf [ (t.submodule { options = {
            mode = lib.mkOption {
              type = t.enum [ "provider-default" ];
            };
          }; }) (t.submodule { options = {
            mode = lib.mkOption {
              type = t.enum [ "authorization-bearer" ];
            };
            token = lib.mkOption {
              type = t.oneOf [ (t.str) (t.submodule { options = {
              source = lib.mkOption {
                type = t.enum [ "env" "file" "exec" "store" ];
              };
              id = lib.mkOption {
                type = t.str;
              };
              provider = lib.mkOption {
                type = t.str;
              };
            }; }) ];
            };
          }; }) (t.submodule { options = {
            headerName = lib.mkOption {
              type = t.str;
            };
            mode = lib.mkOption {
              type = t.enum [ "header" ];
            };
            prefix = lib.mkOption {
              type = t.nullOr (t.str);
              default = null;
            };
            value = lib.mkOption {
              type = t.oneOf [ (t.str) (t.submodule { options = {
              source = lib.mkOption {
                type = t.enum [ "env" "file" "exec" "store" ];
              };
              id = lib.mkOption {
                type = t.str;
              };
              provider = lib.mkOption {
                type = t.str;
              };
            }; }) ];
            };
          }; }) ]);
            default = null;
          };
          headers = lib.mkOption {
            type = t.nullOr (t.attrsOf (t.oneOf [ (t.str) (t.submodule { options = {
            source = lib.mkOption {
              type = t.enum [ "env" "file" "exec" "store" ];
            };
            id = lib.mkOption {
              type = t.str;
            };
            provider = lib.mkOption {
              type = t.str;
            };
          }; }) ]));
            default = null;
          };
          proxy = lib.mkOption {
            type = t.nullOr (t.oneOf [ (t.submodule { options = {
            mode = lib.mkOption {
              type = t.enum [ "env-proxy" ];
            };
            tls = lib.mkOption {
              type = t.nullOr (t.submodule { options = {
              ca = lib.mkOption {
                type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
                source = lib.mkOption {
                  type = t.enum [ "env" "file" "exec" "store" ];
                };
                id = lib.mkOption {
                  type = t.str;
                };
                provider = lib.mkOption {
                  type = t.str;
                };
              }; }) ]);
                default = null;
              };
              cert = lib.mkOption {
                type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
                source = lib.mkOption {
                  type = t.enum [ "env" "file" "exec" "store" ];
                };
                id = lib.mkOption {
                  type = t.str;
                };
                provider = lib.mkOption {
                  type = t.str;
                };
              }; }) ]);
                default = null;
              };
              insecureSkipVerify = lib.mkOption {
                type = t.nullOr (t.bool);
                default = null;
              };
              key = lib.mkOption {
                type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
                source = lib.mkOption {
                  type = t.enum [ "env" "file" "exec" "store" ];
                };
                id = lib.mkOption {
                  type = t.str;
                };
                provider = lib.mkOption {
                  type = t.str;
                };
              }; }) ]);
                default = null;
              };
              passphrase = lib.mkOption {
                type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
                source = lib.mkOption {
                  type = t.enum [ "env" "file" "exec" "store" ];
                };
                id = lib.mkOption {
                  type = t.str;
                };
                provider = lib.mkOption {
                  type = t.str;
                };
              }; }) ]);
                default = null;
              };
              serverName = lib.mkOption {
                type = t.nullOr (t.str);
                default = null;
              };
            }; });
              default = null;
            };
          }; }) (t.submodule { options = {
            mode = lib.mkOption {
              type = t.enum [ "explicit-proxy" ];
            };
            tls = lib.mkOption {
              type = t.nullOr (t.submodule { options = {
              ca = lib.mkOption {
                type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
                source = lib.mkOption {
                  type = t.enum [ "env" "file" "exec" "store" ];
                };
                id = lib.mkOption {
                  type = t.str;
                };
                provider = lib.mkOption {
                  type = t.str;
                };
              }; }) ]);
                default = null;
              };
              cert = lib.mkOption {
                type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
                source = lib.mkOption {
                  type = t.enum [ "env" "file" "exec" "store" ];
                };
                id = lib.mkOption {
                  type = t.str;
                };
                provider = lib.mkOption {
                  type = t.str;
                };
              }; }) ]);
                default = null;
              };
              insecureSkipVerify = lib.mkOption {
                type = t.nullOr (t.bool);
                default = null;
              };
              key = lib.mkOption {
                type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
                source = lib.mkOption {
                  type = t.enum [ "env" "file" "exec" "store" ];
                };
                id = lib.mkOption {
                  type = t.str;
                };
                provider = lib.mkOption {
                  type = t.str;
                };
              }; }) ]);
                default = null;
              };
              passphrase = lib.mkOption {
                type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
                source = lib.mkOption {
                  type = t.enum [ "env" "file" "exec" "store" ];
                };
                id = lib.mkOption {
                  type = t.str;
                };
                provider = lib.mkOption {
                  type = t.str;
                };
              }; }) ]);
                default = null;
              };
              serverName = lib.mkOption {
                type = t.nullOr (t.str);
                default = null;
              };
            }; });
              default = null;
            };
            url = lib.mkOption {
              type = t.str;
            };
          }; }) ]);
            default = null;
          };
          tls = lib.mkOption {
            type = t.nullOr (t.submodule { options = {
            ca = lib.mkOption {
              type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
              source = lib.mkOption {
                type = t.enum [ "env" "file" "exec" "store" ];
              };
              id = lib.mkOption {
                type = t.str;
              };
              provider = lib.mkOption {
                type = t.str;
              };
            }; }) ]);
              default = null;
            };
            cert = lib.mkOption {
              type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
              source = lib.mkOption {
                type = t.enum [ "env" "file" "exec" "store" ];
              };
              id = lib.mkOption {
                type = t.str;
              };
              provider = lib.mkOption {
                type = t.str;
              };
            }; }) ]);
              default = null;
            };
            insecureSkipVerify = lib.mkOption {
              type = t.nullOr (t.bool);
              default = null;
            };
            key = lib.mkOption {
              type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
              source = lib.mkOption {
                type = t.enum [ "env" "file" "exec" "store" ];
              };
              id = lib.mkOption {
                type = t.str;
              };
              provider = lib.mkOption {
                type = t.str;
              };
            }; }) ]);
              default = null;
            };
            passphrase = lib.mkOption {
              type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
              source = lib.mkOption {
                type = t.enum [ "env" "file" "exec" "store" ];
              };
              id = lib.mkOption {
                type = t.str;
              };
              provider = lib.mkOption {
                type = t.str;
              };
            }; }) ]);
              default = null;
            };
            serverName = lib.mkOption {
              type = t.nullOr (t.str);
              default = null;
            };
          }; });
            default = null;
          };
        }; });
          default = null;
        };
        scope = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          default = lib.mkOption {
            type = t.nullOr (t.oneOf [ (t.enum [ "allow" ]) (t.enum [ "deny" ]) ]);
            default = null;
          };
          rules = lib.mkOption {
            type = t.nullOr (t.listOf (t.submodule { options = {
            action = lib.mkOption {
              type = t.oneOf [ (t.enum [ "allow" ]) (t.enum [ "deny" ]) ];
            };
            match = lib.mkOption {
              type = t.nullOr (t.submodule { options = {
              channel = lib.mkOption {
                type = t.nullOr (t.str);
                default = null;
              };
              chatType = lib.mkOption {
                type = t.nullOr (t.oneOf [ (t.enum [ "direct" ]) (t.enum [ "group" ]) (t.enum [ "channel" ]) ]);
                default = null;
              };
              keyPrefix = lib.mkOption {
                type = t.nullOr (t.str);
                default = null;
              };
              rawKeyPrefix = lib.mkOption {
                type = t.nullOr (t.str);
                default = null;
              };
            }; });
              default = null;
            };
          }; }));
            default = null;
          };
        }; });
          default = null;
        };
        timeoutSeconds = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
      }; });
        default = null;
      };
      concurrency = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      image = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        attachments = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          maxAttachments = lib.mkOption {
            type = t.nullOr (t.int);
            default = null;
          };
          mode = lib.mkOption {
            type = t.nullOr (t.oneOf [ (t.enum [ "first" ]) (t.enum [ "all" ]) ]);
            default = null;
          };
          prefer = lib.mkOption {
            type = t.nullOr (t.oneOf [ (t.enum [ "first" ]) (t.enum [ "last" ]) (t.enum [ "path" ]) (t.enum [ "url" ]) ]);
            default = null;
          };
        }; });
          default = null;
        };
        baseUrl = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        enabled = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
        headers = lib.mkOption {
          type = t.nullOr (t.attrsOf (t.str));
          default = null;
        };
        language = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        maxBytes = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        maxChars = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        preferredModel = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        prompt = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        providerOptions = lib.mkOption {
          type = t.nullOr (t.attrsOf (t.attrsOf (t.oneOf [ (t.str) (t.number) (t.bool) ])));
          default = null;
        };
        request = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          auth = lib.mkOption {
            type = t.nullOr (t.oneOf [ (t.submodule { options = {
            mode = lib.mkOption {
              type = t.enum [ "provider-default" ];
            };
          }; }) (t.submodule { options = {
            mode = lib.mkOption {
              type = t.enum [ "authorization-bearer" ];
            };
            token = lib.mkOption {
              type = t.oneOf [ (t.str) (t.submodule { options = {
              source = lib.mkOption {
                type = t.enum [ "env" "file" "exec" "store" ];
              };
              id = lib.mkOption {
                type = t.str;
              };
              provider = lib.mkOption {
                type = t.str;
              };
            }; }) ];
            };
          }; }) (t.submodule { options = {
            headerName = lib.mkOption {
              type = t.str;
            };
            mode = lib.mkOption {
              type = t.enum [ "header" ];
            };
            prefix = lib.mkOption {
              type = t.nullOr (t.str);
              default = null;
            };
            value = lib.mkOption {
              type = t.oneOf [ (t.str) (t.submodule { options = {
              source = lib.mkOption {
                type = t.enum [ "env" "file" "exec" "store" ];
              };
              id = lib.mkOption {
                type = t.str;
              };
              provider = lib.mkOption {
                type = t.str;
              };
            }; }) ];
            };
          }; }) ]);
            default = null;
          };
          headers = lib.mkOption {
            type = t.nullOr (t.attrsOf (t.oneOf [ (t.str) (t.submodule { options = {
            source = lib.mkOption {
              type = t.enum [ "env" "file" "exec" "store" ];
            };
            id = lib.mkOption {
              type = t.str;
            };
            provider = lib.mkOption {
              type = t.str;
            };
          }; }) ]));
            default = null;
          };
          proxy = lib.mkOption {
            type = t.nullOr (t.oneOf [ (t.submodule { options = {
            mode = lib.mkOption {
              type = t.enum [ "env-proxy" ];
            };
            tls = lib.mkOption {
              type = t.nullOr (t.submodule { options = {
              ca = lib.mkOption {
                type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
                source = lib.mkOption {
                  type = t.enum [ "env" "file" "exec" "store" ];
                };
                id = lib.mkOption {
                  type = t.str;
                };
                provider = lib.mkOption {
                  type = t.str;
                };
              }; }) ]);
                default = null;
              };
              cert = lib.mkOption {
                type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
                source = lib.mkOption {
                  type = t.enum [ "env" "file" "exec" "store" ];
                };
                id = lib.mkOption {
                  type = t.str;
                };
                provider = lib.mkOption {
                  type = t.str;
                };
              }; }) ]);
                default = null;
              };
              insecureSkipVerify = lib.mkOption {
                type = t.nullOr (t.bool);
                default = null;
              };
              key = lib.mkOption {
                type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
                source = lib.mkOption {
                  type = t.enum [ "env" "file" "exec" "store" ];
                };
                id = lib.mkOption {
                  type = t.str;
                };
                provider = lib.mkOption {
                  type = t.str;
                };
              }; }) ]);
                default = null;
              };
              passphrase = lib.mkOption {
                type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
                source = lib.mkOption {
                  type = t.enum [ "env" "file" "exec" "store" ];
                };
                id = lib.mkOption {
                  type = t.str;
                };
                provider = lib.mkOption {
                  type = t.str;
                };
              }; }) ]);
                default = null;
              };
              serverName = lib.mkOption {
                type = t.nullOr (t.str);
                default = null;
              };
            }; });
              default = null;
            };
          }; }) (t.submodule { options = {
            mode = lib.mkOption {
              type = t.enum [ "explicit-proxy" ];
            };
            tls = lib.mkOption {
              type = t.nullOr (t.submodule { options = {
              ca = lib.mkOption {
                type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
                source = lib.mkOption {
                  type = t.enum [ "env" "file" "exec" "store" ];
                };
                id = lib.mkOption {
                  type = t.str;
                };
                provider = lib.mkOption {
                  type = t.str;
                };
              }; }) ]);
                default = null;
              };
              cert = lib.mkOption {
                type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
                source = lib.mkOption {
                  type = t.enum [ "env" "file" "exec" "store" ];
                };
                id = lib.mkOption {
                  type = t.str;
                };
                provider = lib.mkOption {
                  type = t.str;
                };
              }; }) ]);
                default = null;
              };
              insecureSkipVerify = lib.mkOption {
                type = t.nullOr (t.bool);
                default = null;
              };
              key = lib.mkOption {
                type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
                source = lib.mkOption {
                  type = t.enum [ "env" "file" "exec" "store" ];
                };
                id = lib.mkOption {
                  type = t.str;
                };
                provider = lib.mkOption {
                  type = t.str;
                };
              }; }) ]);
                default = null;
              };
              passphrase = lib.mkOption {
                type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
                source = lib.mkOption {
                  type = t.enum [ "env" "file" "exec" "store" ];
                };
                id = lib.mkOption {
                  type = t.str;
                };
                provider = lib.mkOption {
                  type = t.str;
                };
              }; }) ]);
                default = null;
              };
              serverName = lib.mkOption {
                type = t.nullOr (t.str);
                default = null;
              };
            }; });
              default = null;
            };
            url = lib.mkOption {
              type = t.str;
            };
          }; }) ]);
            default = null;
          };
          tls = lib.mkOption {
            type = t.nullOr (t.submodule { options = {
            ca = lib.mkOption {
              type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
              source = lib.mkOption {
                type = t.enum [ "env" "file" "exec" "store" ];
              };
              id = lib.mkOption {
                type = t.str;
              };
              provider = lib.mkOption {
                type = t.str;
              };
            }; }) ]);
              default = null;
            };
            cert = lib.mkOption {
              type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
              source = lib.mkOption {
                type = t.enum [ "env" "file" "exec" "store" ];
              };
              id = lib.mkOption {
                type = t.str;
              };
              provider = lib.mkOption {
                type = t.str;
              };
            }; }) ]);
              default = null;
            };
            insecureSkipVerify = lib.mkOption {
              type = t.nullOr (t.bool);
              default = null;
            };
            key = lib.mkOption {
              type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
              source = lib.mkOption {
                type = t.enum [ "env" "file" "exec" "store" ];
              };
              id = lib.mkOption {
                type = t.str;
              };
              provider = lib.mkOption {
                type = t.str;
              };
            }; }) ]);
              default = null;
            };
            passphrase = lib.mkOption {
              type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
              source = lib.mkOption {
                type = t.enum [ "env" "file" "exec" "store" ];
              };
              id = lib.mkOption {
                type = t.str;
              };
              provider = lib.mkOption {
                type = t.str;
              };
            }; }) ]);
              default = null;
            };
            serverName = lib.mkOption {
              type = t.nullOr (t.str);
              default = null;
            };
          }; });
            default = null;
          };
        }; });
          default = null;
        };
        scope = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          default = lib.mkOption {
            type = t.nullOr (t.oneOf [ (t.enum [ "allow" ]) (t.enum [ "deny" ]) ]);
            default = null;
          };
          rules = lib.mkOption {
            type = t.nullOr (t.listOf (t.submodule { options = {
            action = lib.mkOption {
              type = t.oneOf [ (t.enum [ "allow" ]) (t.enum [ "deny" ]) ];
            };
            match = lib.mkOption {
              type = t.nullOr (t.submodule { options = {
              channel = lib.mkOption {
                type = t.nullOr (t.str);
                default = null;
              };
              chatType = lib.mkOption {
                type = t.nullOr (t.oneOf [ (t.enum [ "direct" ]) (t.enum [ "group" ]) (t.enum [ "channel" ]) ]);
                default = null;
              };
              keyPrefix = lib.mkOption {
                type = t.nullOr (t.str);
                default = null;
              };
              rawKeyPrefix = lib.mkOption {
                type = t.nullOr (t.str);
                default = null;
              };
            }; });
              default = null;
            };
          }; }));
            default = null;
          };
        }; });
          default = null;
        };
        timeoutSeconds = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
      }; });
        default = null;
      };
      models = lib.mkOption {
        type = t.nullOr (t.listOf (t.submodule { options = {
        args = lib.mkOption {
          type = t.nullOr (t.listOf (t.str));
          default = null;
        };
        baseUrl = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        capabilities = lib.mkOption {
          type = t.nullOr (t.listOf (t.oneOf [ (t.enum [ "image" ]) (t.enum [ "audio" ]) (t.enum [ "video" ]) ]));
          default = null;
        };
        command = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        headers = lib.mkOption {
          type = t.nullOr (t.attrsOf (t.str));
          default = null;
        };
        language = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        maxBytes = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        maxChars = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        model = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        preferredProfile = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        profile = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        prompt = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        provider = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        providerOptions = lib.mkOption {
          type = t.nullOr (t.attrsOf (t.attrsOf (t.oneOf [ (t.str) (t.number) (t.bool) ])));
          default = null;
        };
        request = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          auth = lib.mkOption {
            type = t.nullOr (t.oneOf [ (t.submodule { options = {
            mode = lib.mkOption {
              type = t.enum [ "provider-default" ];
            };
          }; }) (t.submodule { options = {
            mode = lib.mkOption {
              type = t.enum [ "authorization-bearer" ];
            };
            token = lib.mkOption {
              type = t.oneOf [ (t.str) (t.submodule { options = {
              source = lib.mkOption {
                type = t.enum [ "env" "file" "exec" "store" ];
              };
              id = lib.mkOption {
                type = t.str;
              };
              provider = lib.mkOption {
                type = t.str;
              };
            }; }) ];
            };
          }; }) (t.submodule { options = {
            headerName = lib.mkOption {
              type = t.str;
            };
            mode = lib.mkOption {
              type = t.enum [ "header" ];
            };
            prefix = lib.mkOption {
              type = t.nullOr (t.str);
              default = null;
            };
            value = lib.mkOption {
              type = t.oneOf [ (t.str) (t.submodule { options = {
              source = lib.mkOption {
                type = t.enum [ "env" "file" "exec" "store" ];
              };
              id = lib.mkOption {
                type = t.str;
              };
              provider = lib.mkOption {
                type = t.str;
              };
            }; }) ];
            };
          }; }) ]);
            default = null;
          };
          headers = lib.mkOption {
            type = t.nullOr (t.attrsOf (t.oneOf [ (t.str) (t.submodule { options = {
            source = lib.mkOption {
              type = t.enum [ "env" "file" "exec" "store" ];
            };
            id = lib.mkOption {
              type = t.str;
            };
            provider = lib.mkOption {
              type = t.str;
            };
          }; }) ]));
            default = null;
          };
          proxy = lib.mkOption {
            type = t.nullOr (t.oneOf [ (t.submodule { options = {
            mode = lib.mkOption {
              type = t.enum [ "env-proxy" ];
            };
            tls = lib.mkOption {
              type = t.nullOr (t.submodule { options = {
              ca = lib.mkOption {
                type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
                source = lib.mkOption {
                  type = t.enum [ "env" "file" "exec" "store" ];
                };
                id = lib.mkOption {
                  type = t.str;
                };
                provider = lib.mkOption {
                  type = t.str;
                };
              }; }) ]);
                default = null;
              };
              cert = lib.mkOption {
                type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
                source = lib.mkOption {
                  type = t.enum [ "env" "file" "exec" "store" ];
                };
                id = lib.mkOption {
                  type = t.str;
                };
                provider = lib.mkOption {
                  type = t.str;
                };
              }; }) ]);
                default = null;
              };
              insecureSkipVerify = lib.mkOption {
                type = t.nullOr (t.bool);
                default = null;
              };
              key = lib.mkOption {
                type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
                source = lib.mkOption {
                  type = t.enum [ "env" "file" "exec" "store" ];
                };
                id = lib.mkOption {
                  type = t.str;
                };
                provider = lib.mkOption {
                  type = t.str;
                };
              }; }) ]);
                default = null;
              };
              passphrase = lib.mkOption {
                type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
                source = lib.mkOption {
                  type = t.enum [ "env" "file" "exec" "store" ];
                };
                id = lib.mkOption {
                  type = t.str;
                };
                provider = lib.mkOption {
                  type = t.str;
                };
              }; }) ]);
                default = null;
              };
              serverName = lib.mkOption {
                type = t.nullOr (t.str);
                default = null;
              };
            }; });
              default = null;
            };
          }; }) (t.submodule { options = {
            mode = lib.mkOption {
              type = t.enum [ "explicit-proxy" ];
            };
            tls = lib.mkOption {
              type = t.nullOr (t.submodule { options = {
              ca = lib.mkOption {
                type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
                source = lib.mkOption {
                  type = t.enum [ "env" "file" "exec" "store" ];
                };
                id = lib.mkOption {
                  type = t.str;
                };
                provider = lib.mkOption {
                  type = t.str;
                };
              }; }) ]);
                default = null;
              };
              cert = lib.mkOption {
                type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
                source = lib.mkOption {
                  type = t.enum [ "env" "file" "exec" "store" ];
                };
                id = lib.mkOption {
                  type = t.str;
                };
                provider = lib.mkOption {
                  type = t.str;
                };
              }; }) ]);
                default = null;
              };
              insecureSkipVerify = lib.mkOption {
                type = t.nullOr (t.bool);
                default = null;
              };
              key = lib.mkOption {
                type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
                source = lib.mkOption {
                  type = t.enum [ "env" "file" "exec" "store" ];
                };
                id = lib.mkOption {
                  type = t.str;
                };
                provider = lib.mkOption {
                  type = t.str;
                };
              }; }) ]);
                default = null;
              };
              passphrase = lib.mkOption {
                type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
                source = lib.mkOption {
                  type = t.enum [ "env" "file" "exec" "store" ];
                };
                id = lib.mkOption {
                  type = t.str;
                };
                provider = lib.mkOption {
                  type = t.str;
                };
              }; }) ]);
                default = null;
              };
              serverName = lib.mkOption {
                type = t.nullOr (t.str);
                default = null;
              };
            }; });
              default = null;
            };
            url = lib.mkOption {
              type = t.str;
            };
          }; }) ]);
            default = null;
          };
          tls = lib.mkOption {
            type = t.nullOr (t.submodule { options = {
            ca = lib.mkOption {
              type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
              source = lib.mkOption {
                type = t.enum [ "env" "file" "exec" "store" ];
              };
              id = lib.mkOption {
                type = t.str;
              };
              provider = lib.mkOption {
                type = t.str;
              };
            }; }) ]);
              default = null;
            };
            cert = lib.mkOption {
              type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
              source = lib.mkOption {
                type = t.enum [ "env" "file" "exec" "store" ];
              };
              id = lib.mkOption {
                type = t.str;
              };
              provider = lib.mkOption {
                type = t.str;
              };
            }; }) ]);
              default = null;
            };
            insecureSkipVerify = lib.mkOption {
              type = t.nullOr (t.bool);
              default = null;
            };
            key = lib.mkOption {
              type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
              source = lib.mkOption {
                type = t.enum [ "env" "file" "exec" "store" ];
              };
              id = lib.mkOption {
                type = t.str;
              };
              provider = lib.mkOption {
                type = t.str;
              };
            }; }) ]);
              default = null;
            };
            passphrase = lib.mkOption {
              type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
              source = lib.mkOption {
                type = t.enum [ "env" "file" "exec" "store" ];
              };
              id = lib.mkOption {
                type = t.str;
              };
              provider = lib.mkOption {
                type = t.str;
              };
            }; }) ]);
              default = null;
            };
            serverName = lib.mkOption {
              type = t.nullOr (t.str);
              default = null;
            };
          }; });
            default = null;
          };
        }; });
          default = null;
        };
        timeoutSeconds = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        type = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.enum [ "provider" ]) (t.enum [ "cli" ]) ]);
          default = null;
        };
      }; }));
        default = null;
      };
      video = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        attachments = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          maxAttachments = lib.mkOption {
            type = t.nullOr (t.int);
            default = null;
          };
          mode = lib.mkOption {
            type = t.nullOr (t.oneOf [ (t.enum [ "first" ]) (t.enum [ "all" ]) ]);
            default = null;
          };
          prefer = lib.mkOption {
            type = t.nullOr (t.oneOf [ (t.enum [ "first" ]) (t.enum [ "last" ]) (t.enum [ "path" ]) (t.enum [ "url" ]) ]);
            default = null;
          };
        }; });
          default = null;
        };
        baseUrl = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        enabled = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
        headers = lib.mkOption {
          type = t.nullOr (t.attrsOf (t.str));
          default = null;
        };
        language = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        maxBytes = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        maxChars = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        preferredModel = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        prompt = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        providerOptions = lib.mkOption {
          type = t.nullOr (t.attrsOf (t.attrsOf (t.oneOf [ (t.str) (t.number) (t.bool) ])));
          default = null;
        };
        request = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          auth = lib.mkOption {
            type = t.nullOr (t.oneOf [ (t.submodule { options = {
            mode = lib.mkOption {
              type = t.enum [ "provider-default" ];
            };
          }; }) (t.submodule { options = {
            mode = lib.mkOption {
              type = t.enum [ "authorization-bearer" ];
            };
            token = lib.mkOption {
              type = t.oneOf [ (t.str) (t.submodule { options = {
              source = lib.mkOption {
                type = t.enum [ "env" "file" "exec" "store" ];
              };
              id = lib.mkOption {
                type = t.str;
              };
              provider = lib.mkOption {
                type = t.str;
              };
            }; }) ];
            };
          }; }) (t.submodule { options = {
            headerName = lib.mkOption {
              type = t.str;
            };
            mode = lib.mkOption {
              type = t.enum [ "header" ];
            };
            prefix = lib.mkOption {
              type = t.nullOr (t.str);
              default = null;
            };
            value = lib.mkOption {
              type = t.oneOf [ (t.str) (t.submodule { options = {
              source = lib.mkOption {
                type = t.enum [ "env" "file" "exec" "store" ];
              };
              id = lib.mkOption {
                type = t.str;
              };
              provider = lib.mkOption {
                type = t.str;
              };
            }; }) ];
            };
          }; }) ]);
            default = null;
          };
          headers = lib.mkOption {
            type = t.nullOr (t.attrsOf (t.oneOf [ (t.str) (t.submodule { options = {
            source = lib.mkOption {
              type = t.enum [ "env" "file" "exec" "store" ];
            };
            id = lib.mkOption {
              type = t.str;
            };
            provider = lib.mkOption {
              type = t.str;
            };
          }; }) ]));
            default = null;
          };
          proxy = lib.mkOption {
            type = t.nullOr (t.oneOf [ (t.submodule { options = {
            mode = lib.mkOption {
              type = t.enum [ "env-proxy" ];
            };
            tls = lib.mkOption {
              type = t.nullOr (t.submodule { options = {
              ca = lib.mkOption {
                type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
                source = lib.mkOption {
                  type = t.enum [ "env" "file" "exec" "store" ];
                };
                id = lib.mkOption {
                  type = t.str;
                };
                provider = lib.mkOption {
                  type = t.str;
                };
              }; }) ]);
                default = null;
              };
              cert = lib.mkOption {
                type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
                source = lib.mkOption {
                  type = t.enum [ "env" "file" "exec" "store" ];
                };
                id = lib.mkOption {
                  type = t.str;
                };
                provider = lib.mkOption {
                  type = t.str;
                };
              }; }) ]);
                default = null;
              };
              insecureSkipVerify = lib.mkOption {
                type = t.nullOr (t.bool);
                default = null;
              };
              key = lib.mkOption {
                type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
                source = lib.mkOption {
                  type = t.enum [ "env" "file" "exec" "store" ];
                };
                id = lib.mkOption {
                  type = t.str;
                };
                provider = lib.mkOption {
                  type = t.str;
                };
              }; }) ]);
                default = null;
              };
              passphrase = lib.mkOption {
                type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
                source = lib.mkOption {
                  type = t.enum [ "env" "file" "exec" "store" ];
                };
                id = lib.mkOption {
                  type = t.str;
                };
                provider = lib.mkOption {
                  type = t.str;
                };
              }; }) ]);
                default = null;
              };
              serverName = lib.mkOption {
                type = t.nullOr (t.str);
                default = null;
              };
            }; });
              default = null;
            };
          }; }) (t.submodule { options = {
            mode = lib.mkOption {
              type = t.enum [ "explicit-proxy" ];
            };
            tls = lib.mkOption {
              type = t.nullOr (t.submodule { options = {
              ca = lib.mkOption {
                type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
                source = lib.mkOption {
                  type = t.enum [ "env" "file" "exec" "store" ];
                };
                id = lib.mkOption {
                  type = t.str;
                };
                provider = lib.mkOption {
                  type = t.str;
                };
              }; }) ]);
                default = null;
              };
              cert = lib.mkOption {
                type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
                source = lib.mkOption {
                  type = t.enum [ "env" "file" "exec" "store" ];
                };
                id = lib.mkOption {
                  type = t.str;
                };
                provider = lib.mkOption {
                  type = t.str;
                };
              }; }) ]);
                default = null;
              };
              insecureSkipVerify = lib.mkOption {
                type = t.nullOr (t.bool);
                default = null;
              };
              key = lib.mkOption {
                type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
                source = lib.mkOption {
                  type = t.enum [ "env" "file" "exec" "store" ];
                };
                id = lib.mkOption {
                  type = t.str;
                };
                provider = lib.mkOption {
                  type = t.str;
                };
              }; }) ]);
                default = null;
              };
              passphrase = lib.mkOption {
                type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
                source = lib.mkOption {
                  type = t.enum [ "env" "file" "exec" "store" ];
                };
                id = lib.mkOption {
                  type = t.str;
                };
                provider = lib.mkOption {
                  type = t.str;
                };
              }; }) ]);
                default = null;
              };
              serverName = lib.mkOption {
                type = t.nullOr (t.str);
                default = null;
              };
            }; });
              default = null;
            };
            url = lib.mkOption {
              type = t.str;
            };
          }; }) ]);
            default = null;
          };
          tls = lib.mkOption {
            type = t.nullOr (t.submodule { options = {
            ca = lib.mkOption {
              type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
              source = lib.mkOption {
                type = t.enum [ "env" "file" "exec" "store" ];
              };
              id = lib.mkOption {
                type = t.str;
              };
              provider = lib.mkOption {
                type = t.str;
              };
            }; }) ]);
              default = null;
            };
            cert = lib.mkOption {
              type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
              source = lib.mkOption {
                type = t.enum [ "env" "file" "exec" "store" ];
              };
              id = lib.mkOption {
                type = t.str;
              };
              provider = lib.mkOption {
                type = t.str;
              };
            }; }) ]);
              default = null;
            };
            insecureSkipVerify = lib.mkOption {
              type = t.nullOr (t.bool);
              default = null;
            };
            key = lib.mkOption {
              type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
              source = lib.mkOption {
                type = t.enum [ "env" "file" "exec" "store" ];
              };
              id = lib.mkOption {
                type = t.str;
              };
              provider = lib.mkOption {
                type = t.str;
              };
            }; }) ]);
              default = null;
            };
            passphrase = lib.mkOption {
              type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
              source = lib.mkOption {
                type = t.enum [ "env" "file" "exec" "store" ];
              };
              id = lib.mkOption {
                type = t.str;
              };
              provider = lib.mkOption {
                type = t.str;
              };
            }; }) ]);
              default = null;
            };
            serverName = lib.mkOption {
              type = t.nullOr (t.str);
              default = null;
            };
          }; });
            default = null;
          };
        }; });
          default = null;
        };
        scope = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          default = lib.mkOption {
            type = t.nullOr (t.oneOf [ (t.enum [ "allow" ]) (t.enum [ "deny" ]) ]);
            default = null;
          };
          rules = lib.mkOption {
            type = t.nullOr (t.listOf (t.submodule { options = {
            action = lib.mkOption {
              type = t.oneOf [ (t.enum [ "allow" ]) (t.enum [ "deny" ]) ];
            };
            match = lib.mkOption {
              type = t.nullOr (t.submodule { options = {
              channel = lib.mkOption {
                type = t.nullOr (t.str);
                default = null;
              };
              chatType = lib.mkOption {
                type = t.nullOr (t.oneOf [ (t.enum [ "direct" ]) (t.enum [ "group" ]) (t.enum [ "channel" ]) ]);
                default = null;
              };
              keyPrefix = lib.mkOption {
                type = t.nullOr (t.str);
                default = null;
              };
              rawKeyPrefix = lib.mkOption {
                type = t.nullOr (t.str);
                default = null;
              };
            }; });
              default = null;
            };
          }; }));
            default = null;
          };
        }; });
          default = null;
        };
        timeoutSeconds = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
      }; });
        default = null;
      };
    }; });
      default = null;
    };
    message = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      actions = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        allow = lib.mkOption {
          type = t.nullOr (t.listOf (t.str));
          default = null;
        };
      }; });
        default = null;
      };
      broadcast = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        enabled = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
      }; });
        default = null;
      };
      crossContext = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        allowAcrossProviders = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
        allowWithinProvider = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
        marker = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          enabled = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          prefix = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          suffix = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
        }; });
          default = null;
        };
      }; });
        default = null;
      };
    }; });
      default = null;
    };
    profile = lib.mkOption {
      type = t.nullOr (t.oneOf [ (t.enum [ "minimal" ]) (t.enum [ "coding" ]) (t.enum [ "messaging" ]) (t.enum [ "full" ]) ]);
      default = null;
    };
    sandbox = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      tools = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        allow = lib.mkOption {
          type = t.nullOr (t.listOf (t.str));
          default = null;
        };
        alsoAllow = lib.mkOption {
          type = t.nullOr (t.listOf (t.str));
          default = null;
        };
        deny = lib.mkOption {
          type = t.nullOr (t.listOf (t.str));
          default = null;
        };
      }; });
        default = null;
      };
    }; });
      default = null;
    };
    sessions = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      allowThreadTargets = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      visibility = lib.mkOption {
        type = t.nullOr (t.enum [ "self" "tree" "agent" "all" ]);
        default = null;
      };
    }; });
      default = null;
    };
    sessions_spawn = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      attachments = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        enabled = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
        maxFileBytes = lib.mkOption {
          type = t.nullOr (t.number);
          default = null;
        };
        maxFiles = lib.mkOption {
          type = t.nullOr (t.number);
          default = null;
        };
        maxTotalBytes = lib.mkOption {
          type = t.nullOr (t.number);
          default = null;
        };
        retainOnSessionKeep = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
      }; });
        default = null;
      };
    }; });
      default = null;
    };
    subagents = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      tools = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        allow = lib.mkOption {
          type = t.nullOr (t.listOf (t.str));
          default = null;
        };
        alsoAllow = lib.mkOption {
          type = t.nullOr (t.listOf (t.str));
          default = null;
        };
        deny = lib.mkOption {
          type = t.nullOr (t.listOf (t.str));
          default = null;
        };
      }; });
        default = null;
      };
    }; });
      default = null;
    };
    swarm = lib.mkOption {
      type = t.nullOr (t.oneOf [ (t.bool) (t.submodule { options = {
      defaultAgentId = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      enabled = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      maxChildrenPerGroup = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      maxConcurrent = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      maxTotalPerGroup = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      waitTimeoutSecondsMax = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
    }; }) ]);
      default = null;
    };
    toolSearch = lib.mkOption {
      type = t.nullOr (t.oneOf [ (t.bool) (t.submodule { options = {
      enabled = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      maxSearchLimit = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      mode = lib.mkOption {
        type = t.nullOr (t.enum [ "tools" "directory" ]);
        default = null;
      };
      searchDefaultLimit = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
    }; }) ]);
      default = null;
    };
    toolsBySender = lib.mkOption {
      type = t.nullOr (t.attrsOf (t.submodule { options = {
      allow = lib.mkOption {
        type = t.nullOr (t.listOf (t.str));
        default = null;
      };
      alsoAllow = lib.mkOption {
        type = t.nullOr (t.listOf (t.str));
        default = null;
      };
      deny = lib.mkOption {
        type = t.nullOr (t.listOf (t.str));
        default = null;
      };
    }; }));
      default = null;
    };
    updatePlan = lib.mkOption {
      type = t.nullOr (t.bool);
      default = null;
    };
    web = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      fetch = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        cacheTtlMinutes = lib.mkOption {
          type = t.nullOr (t.number);
          default = null;
        };
        enabled = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
        headers = lib.mkOption {
          type = t.nullOr (t.attrsOf (t.str));
          default = null;
        };
        maxChars = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        maxCharsCap = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        maxRedirects = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        maxResponseBytes = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        provider = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        readability = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
        ssrfPolicy = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          allowIpv6UniqueLocalRange = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          allowRfc2544BenchmarkRange = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          allowedHostnames = lib.mkOption {
            type = t.nullOr (t.listOf (t.str));
            default = null;
          };
          blockedHostnames = lib.mkOption {
            type = t.nullOr (t.listOf (t.str));
            default = null;
          };
          dangerouslyAllowPrivateNetwork = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
        }; });
          default = null;
        };
        timeoutSeconds = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        useTrustedEnvProxy = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
        userAgent = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
      }; });
        default = null;
      };
      search = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        cacheTtlMinutes = lib.mkOption {
          type = t.nullOr (t.number);
          default = null;
        };
        enabled = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
        maxResults = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        openaiCodex = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          allowedDomains = lib.mkOption {
            type = t.nullOr (t.anything);
            default = null;
          };
          contextSize = lib.mkOption {
            type = t.nullOr (t.oneOf [ (t.enum [ "low" ]) (t.enum [ "medium" ]) (t.enum [ "high" ]) ]);
            default = null;
          };
          enabled = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          mode = lib.mkOption {
            type = t.nullOr (t.oneOf [ (t.enum [ "cached" ]) (t.enum [ "live" ]) ]);
            default = null;
          };
          userLocation = lib.mkOption {
            type = t.nullOr (t.anything);
            default = null;
          };
        }; });
          default = null;
        };
        provider = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        timeoutSeconds = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
      }; });
        default = null;
      };
    }; });
      default = null;
    };
  }; });
    default = null;
  };

  transcripts = lib.mkOption {
    type = t.nullOr (t.submodule { options = {
    autoStart = lib.mkOption {
      type = t.nullOr (t.listOf (t.submodule { options = {
      accountId = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      channelId = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      guildId = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      meetingUrl = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      providerId = lib.mkOption {
        type = t.str;
      };
      sessionId = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      title = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      whenOccupied = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
    }; }));
      default = null;
    };
    enabled = lib.mkOption {
      type = t.nullOr (t.bool);
      default = null;
    };
  }; });
    default = null;
  };

  tts = lib.mkOption {
    type = t.nullOr (t.submodule { options = {
    auto = lib.mkOption {
      type = t.nullOr (t.enum [ "off" "always" "inbound" "tagged" ]);
      default = null;
    };
    enabled = lib.mkOption {
      type = t.nullOr (t.bool);
      default = null;
    };
    maxTextLength = lib.mkOption {
      type = t.nullOr (t.int);
      default = null;
    };
    mode = lib.mkOption {
      type = t.nullOr (t.enum [ "final" "all" ]);
      default = null;
    };
    modelOverrides = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      allowModelId = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      allowNormalization = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      allowProvider = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      allowSeed = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      allowText = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      allowVoice = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      allowVoiceSettings = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      enabled = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
    }; });
      default = null;
    };
    persona = lib.mkOption {
      type = t.nullOr (t.str);
      default = null;
    };
    personas = lib.mkOption {
      type = t.nullOr (t.attrsOf (t.submodule { options = {
      description = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      fallbackPolicy = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.enum [ "preserve-persona" ]) (t.enum [ "provider-defaults" ]) (t.enum [ "fail" ]) ]);
        default = null;
      };
      label = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      provider = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      providers = lib.mkOption {
        type = t.nullOr (t.attrsOf (t.submodule { options = {
        apiKey = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
          source = lib.mkOption {
            type = t.enum [ "env" "file" "exec" "store" ];
          };
          id = lib.mkOption {
            type = t.str;
          };
          provider = lib.mkOption {
            type = t.str;
          };
        }; }) ]);
          default = null;
        };
      }; }));
        default = null;
      };
    }; }));
      default = null;
    };
    provider = lib.mkOption {
      type = t.nullOr (t.str);
      default = null;
    };
    providers = lib.mkOption {
      type = t.nullOr (t.attrsOf (t.submodule { options = {
      apiKey = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
        source = lib.mkOption {
          type = t.enum [ "env" "file" "exec" "store" ];
        };
        id = lib.mkOption {
          type = t.str;
        };
        provider = lib.mkOption {
          type = t.str;
        };
      }; }) ]);
        default = null;
      };
    }; }));
      default = null;
    };
    summaryModel = lib.mkOption {
      type = t.nullOr (t.str);
      default = null;
    };
    timeoutMs = lib.mkOption {
      type = t.nullOr (t.int);
      default = null;
    };
  }; });
    default = null;
  };

  ui = lib.mkOption {
    type = t.nullOr (t.submodule { options = {
    prefs = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      accent = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.enum [ "theme" ]) (t.anything) ]);
        default = null;
      };
      chatFollowUpMode = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.enum [ "steer" ]) (t.enum [ "queue" ]) ]);
        default = null;
      };
      chatPersistCommentary = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      chatSendShortcut = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.enum [ "enter" ]) (t.enum [ "modifier-enter" ]) ]);
        default = null;
      };
      chatShowThinking = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      chatShowToolCalls = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      locale = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      sidebarEntries = lib.mkOption {
        type = t.nullOr (t.listOf (t.str));
        default = null;
      };
      theme = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.enum [ "claw" ]) (t.enum [ "knot" ]) (t.enum [ "dash" ]) (t.enum [ "absolutely" ]) (t.enum [ "tide" ]) (t.enum [ "beacon" ]) (t.enum [ "phosphor" ]) (t.enum [ "crt" ]) (t.enum [ "manuscript" ]) (t.enum [ "rose" ]) (t.enum [ "miami" ]) (t.enum [ "custom" ]) ]);
        default = null;
      };
      themeMode = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.enum [ "light" ]) (t.enum [ "dark" ]) (t.enum [ "system" ]) ]);
        default = null;
      };
    }; });
      default = null;
    };
    seamColor = lib.mkOption {
      type = t.nullOr (t.str);
      default = null;
    };
  }; });
    default = null;
  };

  update = lib.mkOption {
    type = t.nullOr (t.submodule { options = {
    auto = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      enabled = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
    }; });
      default = null;
    };
    channel = lib.mkOption {
      type = t.nullOr (t.oneOf [ (t.enum [ "stable" ]) (t.enum [ "extended-stable" ]) (t.enum [ "beta" ]) (t.enum [ "dev" ]) ]);
      default = null;
    };
    checkOnStart = lib.mkOption {
      type = t.nullOr (t.bool);
      default = null;
    };
  }; });
    default = null;
  };

  wizard = lib.mkOption {
    type = t.nullOr (t.submodule { options = {
    accessMode = lib.mkOption {
      type = t.nullOr (t.oneOf [ (t.enum [ "full" ]) (t.enum [ "guarded" ]) ]);
      default = null;
    };
    appRecommendations = lib.mkOption {
      type = t.nullOr (t.bool);
      default = null;
    };
    lastRunAt = lib.mkOption {
      type = t.nullOr (t.str);
      default = null;
    };
    lastRunCommand = lib.mkOption {
      type = t.nullOr (t.str);
      default = null;
    };
    lastRunCommit = lib.mkOption {
      type = t.nullOr (t.str);
      default = null;
    };
    lastRunMode = lib.mkOption {
      type = t.nullOr (t.oneOf [ (t.enum [ "local" ]) (t.enum [ "remote" ]) ]);
      default = null;
    };
    lastRunVersion = lib.mkOption {
      type = t.nullOr (t.str);
      default = null;
    };
    securityAcknowledgedAt = lib.mkOption {
      type = t.nullOr (t.str);
      default = null;
    };
  }; });
    default = null;
  };

  worktreeAcceleration = lib.mkOption {
    type = t.nullOr (t.bool);
    default = null;
  };

  worktreeMaxCount = lib.mkOption {
    type = t.nullOr (t.int);
    default = null;
  };

  worktreeRoot = lib.mkOption {
    type = t.nullOr (t.str);
    default = null;
  };
}
