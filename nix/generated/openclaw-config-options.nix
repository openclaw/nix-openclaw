# Generated from upstream OpenClaw schema at rev c645ec4555c017931de0e35ad9847dffae2741ef. DO NOT EDIT.
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
    type = t.nullOr (t.attrsOf (t.oneOf [ (t.submodule { options = {
    channelId = lib.mkOption {
      type = t.str;
    };
    guildId = lib.mkOption {
      type = t.str;
    };
    membership = lib.mkOption {
      type = t.nullOr (t.enum [ "canViewChannel" ]);
      default = null;
    };
    type = lib.mkOption {
      type = t.enum [ "discord.channelAudience" ];
    };
  }; }) (t.submodule { options = {
    members = lib.mkOption {
      type = t.attrsOf (t.listOf (t.str));
    };
    type = lib.mkOption {
      type = t.enum [ "message.senders" ];
    };
  }; }) ]));
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
    maxConcurrentSessions = lib.mkOption {
      type = t.nullOr (t.int);
      default = null;
    };
    runtime = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      installCommand = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      ttlMinutes = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
    }; });
      default = null;
    };
    stream = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      coalesceIdleMs = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      deliveryMode = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.enum [ "live" ]) (t.enum [ "final_only" ]) ]);
        default = null;
      };
      hiddenBoundarySeparator = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.enum [ "none" ]) (t.enum [ "space" ]) (t.enum [ "newline" ]) (t.enum [ "paragraph" ]) ]);
        default = null;
      };
      maxChunkChars = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      maxOutputChars = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      maxSessionUpdateChars = lib.mkOption {
        type = t.nullOr (t.int);
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
      bootstrapPromptTruncationWarning = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.enum [ "off" ]) (t.enum [ "once" ]) (t.enum [ "always" ]) ]);
        default = null;
      };
      bootstrapTotalMaxChars = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      cliBackends = lib.mkOption {
        type = t.nullOr (t.attrsOf (t.submodule { options = {
        args = lib.mkOption {
          type = t.nullOr (t.listOf (t.str));
          default = null;
        };
        clearEnv = lib.mkOption {
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
        imageArg = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        imageMode = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.enum [ "repeat" ]) (t.enum [ "list" ]) ]);
          default = null;
        };
        imagePathScope = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.enum [ "temp" ]) (t.enum [ "workspace" ]) ]);
          default = null;
        };
        input = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.enum [ "arg" ]) (t.enum [ "stdin" ]) ]);
          default = null;
        };
        jsonlDialect = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.enum [ "claude-stream-json" ]) (t.enum [ "gemini-stream-json" ]) ]);
          default = null;
        };
        liveSession = lib.mkOption {
          type = t.nullOr (t.enum [ "claude-stdio" ]);
          default = null;
        };
        maxPromptArgChars = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        modelAliases = lib.mkOption {
          type = t.nullOr (t.attrsOf (t.str));
          default = null;
        };
        modelArg = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        output = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.enum [ "json" ]) (t.enum [ "text" ]) (t.enum [ "jsonl" ]) ]);
          default = null;
        };
        reliability = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          outputLimits = lib.mkOption {
            type = t.nullOr (t.submodule { options = {
            maxTurnLines = lib.mkOption {
              type = t.nullOr (t.int);
              default = null;
            };
            maxTurnRawChars = lib.mkOption {
              type = t.nullOr (t.int);
              default = null;
            };
          }; });
            default = null;
          };
          watchdog = lib.mkOption {
            type = t.nullOr (t.submodule { options = {
            fresh = lib.mkOption {
              type = t.nullOr (t.submodule { options = {
              maxMs = lib.mkOption {
                type = t.nullOr (t.int);
                default = null;
              };
              minMs = lib.mkOption {
                type = t.nullOr (t.int);
                default = null;
              };
              noOutputTimeoutMs = lib.mkOption {
                type = t.nullOr (t.int);
                default = null;
              };
              noOutputTimeoutRatio = lib.mkOption {
                type = t.nullOr (t.number);
                default = null;
              };
            }; });
              default = null;
            };
            resume = lib.mkOption {
              type = t.nullOr (t.submodule { options = {
              maxMs = lib.mkOption {
                type = t.nullOr (t.int);
                default = null;
              };
              minMs = lib.mkOption {
                type = t.nullOr (t.int);
                default = null;
              };
              noOutputTimeoutMs = lib.mkOption {
                type = t.nullOr (t.int);
                default = null;
              };
              noOutputTimeoutRatio = lib.mkOption {
                type = t.nullOr (t.number);
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
        reseedFromRawTranscriptWhenUncompacted = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
        resumeArgs = lib.mkOption {
          type = t.nullOr (t.listOf (t.str));
          default = null;
        };
        resumeOutput = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.enum [ "json" ]) (t.enum [ "text" ]) (t.enum [ "jsonl" ]) ]);
          default = null;
        };
        serialize = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
        sessionArg = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        sessionArgs = lib.mkOption {
          type = t.nullOr (t.listOf (t.str));
          default = null;
        };
        sessionIdFields = lib.mkOption {
          type = t.nullOr (t.listOf (t.str));
          default = null;
        };
        sessionMode = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.enum [ "always" ]) (t.enum [ "existing" ]) (t.enum [ "none" ]) ]);
          default = null;
        };
        systemPromptArg = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        systemPromptFileArg = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        systemPromptFileConfigArg = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        systemPromptFileConfigKey = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        systemPromptMode = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.enum [ "append" ]) (t.enum [ "replace" ]) ]);
          default = null;
        };
        systemPromptWhen = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.enum [ "first" ]) (t.enum [ "always" ]) (t.enum [ "never" ]) ]);
          default = null;
        };
      }; }));
        default = null;
      };
      compaction = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        customInstructions = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        identifierInstructions = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        identifierPolicy = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.enum [ "strict" ]) (t.enum [ "off" ]) (t.enum [ "custom" ]) ]);
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
        maxHistoryShare = lib.mkOption {
          type = t.nullOr (t.number);
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
          prompt = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          softThresholdTokens = lib.mkOption {
            type = t.nullOr (t.int);
            default = null;
          };
          systemPrompt = lib.mkOption {
            type = t.nullOr (t.str);
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
        reserveTokens = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        reserveTokensFloor = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        timeoutSeconds = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        truncateAfterCompaction = lib.mkOption {
          type = t.nullOr (t.bool);
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
        memoryGetDefaultLines = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        memoryGetMaxChars = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        postCompactionMaxChars = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        toolResultMaxChars = lib.mkOption {
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
        hardClearRatio = lib.mkOption {
          type = t.nullOr (t.number);
          default = null;
        };
        keepLastAssistants = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        minPrunableToolChars = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        mode = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.enum [ "off" ]) (t.enum [ "cache-ttl" ]) ]);
          default = null;
        };
        softTrim = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          headChars = lib.mkOption {
            type = t.nullOr (t.int);
            default = null;
          };
          maxChars = lib.mkOption {
            type = t.nullOr (t.int);
            default = null;
          };
          tailChars = lib.mkOption {
            type = t.nullOr (t.int);
            default = null;
          };
        }; });
          default = null;
        };
        softTrimRatio = lib.mkOption {
          type = t.nullOr (t.number);
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
      contextTokens = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      elevatedDefault = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.enum [ "off" ]) (t.enum [ "on" ]) (t.enum [ "ask" ]) (t.enum [ "full" ]) ]);
        default = null;
      };
      embeddedAgent = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
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
      envelopeElapsed = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.enum [ "on" ]) (t.enum [ "off" ]) ]);
        default = null;
      };
      envelopeTimestamp = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.enum [ "on" ]) (t.enum [ "off" ]) ]);
        default = null;
      };
      envelopeTimezone = lib.mkOption {
        type = t.nullOr (t.str);
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
      heartbeat = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        accountId = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        ackMaxChars = lib.mkOption {
          type = t.nullOr (t.int);
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
        includeReasoning = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
        includeSystemPromptSection = lib.mkOption {
          type = t.nullOr (t.bool);
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
        skipWhenBusy = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
        suppressToolErrorWarnings = lib.mkOption {
          type = t.nullOr (t.bool);
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
      imageGenerationModel = lib.mkOption {
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
      mediaGenerationAutoProviderFallback = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      mediaMaxMb = lib.mkOption {
        type = t.nullOr (t.number);
        default = null;
      };
      memorySearch = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        cache = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          enabled = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          maxEntries = lib.mkOption {
            type = t.nullOr (t.int);
            default = null;
          };
        }; });
          default = null;
        };
        chunking = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          overlap = lib.mkOption {
            type = t.nullOr (t.int);
            default = null;
          };
          tokens = lib.mkOption {
            type = t.nullOr (t.int);
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
          type = t.nullOr (t.listOf (t.str));
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
          contextSize = lib.mkOption {
            type = t.nullOr (t.oneOf [ (t.int) (t.enum [ "auto" ]) ]);
            default = null;
          };
          modelCacheDir = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
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
        qmd = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          extraCollections = lib.mkOption {
            type = t.nullOr (t.listOf (t.submodule { options = {
            name = lib.mkOption {
              type = t.nullOr (t.str);
              default = null;
            };
            path = lib.mkOption {
              type = t.str;
            };
            pattern = lib.mkOption {
              type = t.nullOr (t.str);
              default = null;
            };
          }; }));
            default = null;
          };
        }; });
          default = null;
        };
        query = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          hybrid = lib.mkOption {
            type = t.nullOr (t.submodule { options = {
            candidateMultiplier = lib.mkOption {
              type = t.nullOr (t.int);
              default = null;
            };
            enabled = lib.mkOption {
              type = t.nullOr (t.bool);
              default = null;
            };
            mmr = lib.mkOption {
              type = t.nullOr (t.submodule { options = {
              enabled = lib.mkOption {
                type = t.nullOr (t.bool);
                default = null;
              };
              lambda = lib.mkOption {
                type = t.nullOr (t.number);
                default = null;
              };
            }; });
              default = null;
            };
            temporalDecay = lib.mkOption {
              type = t.nullOr (t.submodule { options = {
              enabled = lib.mkOption {
                type = t.nullOr (t.bool);
                default = null;
              };
              halfLifeDays = lib.mkOption {
                type = t.nullOr (t.int);
                default = null;
              };
            }; });
              default = null;
            };
            textWeight = lib.mkOption {
              type = t.nullOr (t.number);
              default = null;
            };
            vectorWeight = lib.mkOption {
              type = t.nullOr (t.number);
              default = null;
            };
          }; });
            default = null;
          };
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
        remote = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          apiKey = lib.mkOption {
            type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
            source = lib.mkOption {
              type = t.enum [ "env" "file" "exec" ];
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
            concurrency = lib.mkOption {
              type = t.nullOr (t.int);
              default = null;
            };
            enabled = lib.mkOption {
              type = t.nullOr (t.bool);
              default = null;
            };
            pollIntervalMs = lib.mkOption {
              type = t.nullOr (t.int);
              default = null;
            };
            timeoutMinutes = lib.mkOption {
              type = t.nullOr (t.int);
              default = null;
            };
            wait = lib.mkOption {
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
          nonBatchConcurrency = lib.mkOption {
            type = t.nullOr (t.int);
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
          driver = lib.mkOption {
            type = t.nullOr (t.enum [ "sqlite" ]);
            default = null;
          };
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
        sync = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          embeddingBatchTimeoutSeconds = lib.mkOption {
            type = t.nullOr (t.int);
            default = null;
          };
          intervalMinutes = lib.mkOption {
            type = t.nullOr (t.int);
            default = null;
          };
          onSearch = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          onSessionStart = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          sessions = lib.mkOption {
            type = t.nullOr (t.submodule { options = {
            deltaBytes = lib.mkOption {
              type = t.nullOr (t.int);
              default = null;
            };
            deltaMessages = lib.mkOption {
              type = t.nullOr (t.int);
              default = null;
            };
            postCompactionForce = lib.mkOption {
              type = t.nullOr (t.bool);
              default = null;
            };
          }; });
            default = null;
          };
          watch = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          watchDebounceMs = lib.mkOption {
            type = t.nullOr (t.int);
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
        params = lib.mkOption {
          type = t.nullOr (t.attrsOf (t.anything));
          default = null;
        };
        streaming = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
      }; }));
        default = null;
      };
      musicGenerationModel = lib.mkOption {
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
      params = lib.mkOption {
        type = t.nullOr (t.attrsOf (t.anything));
        default = null;
      };
      pdfMaxBytesMb = lib.mkOption {
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
      promptOverlays = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        gpt5 = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          personality = lib.mkOption {
            type = t.nullOr (t.oneOf [ (t.enum [ "friendly" ]) (t.enum [ "on" ]) (t.enum [ "off" ]) ]);
            default = null;
          };
        }; });
          default = null;
        };
      }; });
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
      runRetries = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        base = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        max = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        min = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        perProfile = lib.mkOption {
          type = t.nullOr (t.int);
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
          enableNoVnc = lib.mkOption {
            type = t.nullOr (t.bool);
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
              type = t.enum [ "env" "file" "exec" ];
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
              type = t.enum [ "env" "file" "exec" ];
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
              type = t.enum [ "env" "file" "exec" ];
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
      silentReply = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        group = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.enum [ "allow" ]) (t.enum [ "disallow" ]) ]);
          default = null;
        };
        internal = lib.mkOption {
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
        };
        maxSpawnDepth = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
          description = "Maximum nesting depth for sub-agent spawning. 1 = no nesting (default), 2 = sub-agents can spawn sub-sub-agents.";
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
      thinkingDefault = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.enum [ "off" ]) (t.enum [ "minimal" ]) (t.enum [ "low" ]) (t.enum [ "medium" ]) (t.enum [ "high" ]) (t.enum [ "xhigh" ]) (t.enum [ "adaptive" ]) (t.enum [ "max" ]) ]);
        default = null;
      };
      timeFormat = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.enum [ "auto" ]) (t.enum [ "12" ]) (t.enum [ "24" ]) ]);
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
      verboseDefault = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.enum [ "off" ]) (t.enum [ "on" ]) (t.enum [ "full" ]) ]);
        default = null;
      };
      videoGenerationModel = lib.mkOption {
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
    list = lib.mkOption {
      type = t.nullOr (t.listOf (t.submodule { options = {
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
        memoryGetDefaultLines = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        memoryGetMaxChars = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        postCompactionMaxChars = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        toolResultMaxChars = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
      }; });
        default = null;
      };
      contextTokens = lib.mkOption {
        type = t.nullOr (t.int);
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
        type = t.nullOr (t.bool);
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
      heartbeat = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        accountId = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        ackMaxChars = lib.mkOption {
          type = t.nullOr (t.int);
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
        includeReasoning = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
        includeSystemPromptSection = lib.mkOption {
          type = t.nullOr (t.bool);
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
        skipWhenBusy = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
        suppressToolErrorWarnings = lib.mkOption {
          type = t.nullOr (t.bool);
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
      id = lib.mkOption {
        type = t.str;
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
      memorySearch = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        cache = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          enabled = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          maxEntries = lib.mkOption {
            type = t.nullOr (t.int);
            default = null;
          };
        }; });
          default = null;
        };
        chunking = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          overlap = lib.mkOption {
            type = t.nullOr (t.int);
            default = null;
          };
          tokens = lib.mkOption {
            type = t.nullOr (t.int);
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
          type = t.nullOr (t.listOf (t.str));
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
          contextSize = lib.mkOption {
            type = t.nullOr (t.oneOf [ (t.int) (t.enum [ "auto" ]) ]);
            default = null;
          };
          modelCacheDir = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
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
        qmd = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          extraCollections = lib.mkOption {
            type = t.nullOr (t.listOf (t.submodule { options = {
            name = lib.mkOption {
              type = t.nullOr (t.str);
              default = null;
            };
            path = lib.mkOption {
              type = t.str;
            };
            pattern = lib.mkOption {
              type = t.nullOr (t.str);
              default = null;
            };
          }; }));
            default = null;
          };
        }; });
          default = null;
        };
        query = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          hybrid = lib.mkOption {
            type = t.nullOr (t.submodule { options = {
            candidateMultiplier = lib.mkOption {
              type = t.nullOr (t.int);
              default = null;
            };
            enabled = lib.mkOption {
              type = t.nullOr (t.bool);
              default = null;
            };
            mmr = lib.mkOption {
              type = t.nullOr (t.submodule { options = {
              enabled = lib.mkOption {
                type = t.nullOr (t.bool);
                default = null;
              };
              lambda = lib.mkOption {
                type = t.nullOr (t.number);
                default = null;
              };
            }; });
              default = null;
            };
            temporalDecay = lib.mkOption {
              type = t.nullOr (t.submodule { options = {
              enabled = lib.mkOption {
                type = t.nullOr (t.bool);
                default = null;
              };
              halfLifeDays = lib.mkOption {
                type = t.nullOr (t.int);
                default = null;
              };
            }; });
              default = null;
            };
            textWeight = lib.mkOption {
              type = t.nullOr (t.number);
              default = null;
            };
            vectorWeight = lib.mkOption {
              type = t.nullOr (t.number);
              default = null;
            };
          }; });
            default = null;
          };
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
        remote = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          apiKey = lib.mkOption {
            type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
            source = lib.mkOption {
              type = t.enum [ "env" "file" "exec" ];
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
            concurrency = lib.mkOption {
              type = t.nullOr (t.int);
              default = null;
            };
            enabled = lib.mkOption {
              type = t.nullOr (t.bool);
              default = null;
            };
            pollIntervalMs = lib.mkOption {
              type = t.nullOr (t.int);
              default = null;
            };
            timeoutMinutes = lib.mkOption {
              type = t.nullOr (t.int);
              default = null;
            };
            wait = lib.mkOption {
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
          nonBatchConcurrency = lib.mkOption {
            type = t.nullOr (t.int);
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
          driver = lib.mkOption {
            type = t.nullOr (t.enum [ "sqlite" ]);
            default = null;
          };
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
        sync = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          embeddingBatchTimeoutSeconds = lib.mkOption {
            type = t.nullOr (t.int);
            default = null;
          };
          intervalMinutes = lib.mkOption {
            type = t.nullOr (t.int);
            default = null;
          };
          onSearch = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          onSessionStart = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          sessions = lib.mkOption {
            type = t.nullOr (t.submodule { options = {
            deltaBytes = lib.mkOption {
              type = t.nullOr (t.int);
              default = null;
            };
            deltaMessages = lib.mkOption {
              type = t.nullOr (t.int);
              default = null;
            };
            postCompactionForce = lib.mkOption {
              type = t.nullOr (t.bool);
              default = null;
            };
          }; });
            default = null;
          };
          watch = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          watchDebounceMs = lib.mkOption {
            type = t.nullOr (t.int);
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
        params = lib.mkOption {
          type = t.nullOr (t.attrsOf (t.anything));
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
      runRetries = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        base = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        max = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        min = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        perProfile = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
      }; });
        default = null;
      };
      runtime = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.submodule { options = {
        type = lib.mkOption {
          type = t.enum [ "embedded" ];
        };
      }; }) (t.submodule { options = {
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
        type = lib.mkOption {
          type = t.enum [ "acp" ];
        };
      }; }) ]);
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
          enableNoVnc = lib.mkOption {
            type = t.nullOr (t.bool);
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
              type = t.enum [ "env" "file" "exec" ];
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
              type = t.enum [ "env" "file" "exec" ];
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
              type = t.enum [ "env" "file" "exec" ];
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
        type = t.nullOr (t.enum [ "off" "minimal" "low" "medium" "high" "xhigh" "adaptive" "max" ]);
        default = null;
      };
      toolProgressDetail = lib.mkOption {
        type = t.nullOr (t.enum [ "explain" "raw" ]);
        default = null;
      };
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
          type = t.nullOr (t.oneOf [ (t.bool) (t.submodule { options = {
          enabled = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          languages = lib.mkOption {
            type = t.nullOr (t.listOf (t.enum [ "javascript" "typescript" ]));
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
          runtime = lib.mkOption {
            type = t.nullOr (t.enum [ "quickjs-wasi" ]);
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
          timeoutSec = lib.mkOption {
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
        loopDetection = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          criticalThreshold = lib.mkOption {
            type = t.nullOr (t.int);
            default = null;
          };
          detectors = lib.mkOption {
            type = t.nullOr (t.submodule { options = {
            genericRepeat = lib.mkOption {
              type = t.nullOr (t.bool);
              default = null;
            };
            knownPollNoProgress = lib.mkOption {
              type = t.nullOr (t.bool);
              default = null;
            };
            pingPong = lib.mkOption {
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
          globalCircuitBreakerThreshold = lib.mkOption {
            type = t.nullOr (t.int);
            default = null;
          };
          historySize = lib.mkOption {
            type = t.nullOr (t.int);
            default = null;
          };
          postCompactionGuard = lib.mkOption {
            type = t.nullOr (t.submodule { options = {
            windowSize = lib.mkOption {
              type = t.nullOr (t.int);
              default = null;
            };
          }; });
            default = null;
          };
          unknownToolThreshold = lib.mkOption {
            type = t.nullOr (t.int);
            default = null;
          };
          warningThreshold = lib.mkOption {
            type = t.nullOr (t.int);
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
          allowCrossContextSend = lib.mkOption {
            type = t.nullOr (t.bool);
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
          prompt = lib.mkOption {
            type = t.nullOr (t.submodule { options = {
            accent = lib.mkOption {
              type = t.nullOr (t.str);
              default = null;
            };
            constraints = lib.mkOption {
              type = t.nullOr (t.listOf (t.str));
              default = null;
            };
            pacing = lib.mkOption {
              type = t.nullOr (t.str);
              default = null;
            };
            profile = lib.mkOption {
              type = t.nullOr (t.str);
              default = null;
            };
            sampleContext = lib.mkOption {
              type = t.nullOr (t.str);
              default = null;
            };
            scene = lib.mkOption {
              type = t.nullOr (t.str);
              default = null;
            };
            style = lib.mkOption {
              type = t.nullOr (t.str);
              default = null;
            };
          }; });
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
                type = t.enum [ "env" "file" "exec" ];
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
              type = t.enum [ "env" "file" "exec" ];
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

  audio = lib.mkOption {
    type = t.nullOr (t.submodule { options = {
    transcription = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      command = lib.mkOption {
        type = t.listOf (t.str);
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

  auth = lib.mkOption {
    type = t.nullOr (t.submodule { options = {
    cooldowns = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      authPermanentBackoffMinutes = lib.mkOption {
        type = t.nullOr (t.number);
        default = null;
      };
      authPermanentMaxMinutes = lib.mkOption {
        type = t.nullOr (t.number);
        default = null;
      };
      billingBackoffHours = lib.mkOption {
        type = t.nullOr (t.number);
        default = null;
      };
      billingBackoffHoursByProvider = lib.mkOption {
        type = t.nullOr (t.attrsOf (t.number));
        default = null;
      };
      billingMaxHours = lib.mkOption {
        type = t.nullOr (t.number);
        default = null;
      };
      failureWindowHours = lib.mkOption {
        type = t.nullOr (t.number);
        default = null;
      };
      overloadedBackoffMs = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      overloadedProfileRotations = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      rateLimitedProfileRotations = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
    }; });
      default = null;
    };
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
          type = t.oneOf [ (t.enum [ "direct" ]) (t.enum [ "group" ]) (t.enum [ "channel" ]) (t.enum [ "dm" ]) ];
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
        type = t.nullOr (t.oneOf [ (t.enum [ "main" ]) (t.enum [ "per-peer" ]) (t.enum [ "per-channel-peer" ]) (t.enum [ "per-account-channel-peer" ]) ]);
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
          type = t.oneOf [ (t.enum [ "direct" ]) (t.enum [ "group" ]) (t.enum [ "channel" ]) (t.enum [ "dm" ]) ];
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
    actionTimeoutMs = lib.mkOption {
      type = t.nullOr (t.int);
      default = null;
    };
    attachOnly = lib.mkOption {
      type = t.nullOr (t.bool);
      default = null;
    };
    cdpPortRangeStart = lib.mkOption {
      type = t.nullOr (t.int);
      default = null;
    };
    cdpUrl = lib.mkOption {
      type = t.nullOr (t.str);
      default = null;
    };
    color = lib.mkOption {
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
    extraArgs = lib.mkOption {
      type = t.nullOr (t.listOf (t.str));
      default = null;
    };
    headless = lib.mkOption {
      type = t.nullOr (t.bool);
      default = null;
    };
    localCdpReadyTimeoutMs = lib.mkOption {
      type = t.nullOr (t.int);
      default = null;
    };
    localLaunchTimeoutMs = lib.mkOption {
      type = t.nullOr (t.int);
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
      color = lib.mkOption {
        type = t.str;
      };
      driver = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.enum [ "openclaw" ]) (t.enum [ "clawd" ]) (t.enum [ "existing-session" ]) ]);
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
    remoteCdpHandshakeTimeoutMs = lib.mkOption {
      type = t.nullOr (t.int);
      default = null;
    };
    remoteCdpTimeoutMs = lib.mkOption {
      type = t.nullOr (t.int);
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
      allowedHostnames = lib.mkOption {
        type = t.nullOr (t.listOf (t.str));
        default = null;
      };
      dangerouslyAllowPrivateNetwork = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      hostnameAllowlist = lib.mkOption {
        type = t.nullOr (t.listOf (t.str));
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
      idleMinutes = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      maxTabsPerSession = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      sweepMinutes = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
    }; });
      default = null;
    };
  }; });
    default = null;
  };

  canvasHost = lib.mkOption {
    type = t.nullOr (t.submodule { options = {
    enabled = lib.mkOption {
      type = t.nullOr (t.bool);
      default = null;
    };
    liveReload = lib.mkOption {
      type = t.nullOr (t.bool);
      default = null;
    };
    port = lib.mkOption {
      type = t.nullOr (t.int);
      default = null;
    };
    root = lib.mkOption {
      type = t.nullOr (t.str);
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
      heartbeat = lib.mkOption {
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

  cli = lib.mkOption {
    type = t.nullOr (t.submodule { options = {
    banner = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      taglineMode = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.enum [ "random" ]) (t.enum [ "default" ]) (t.enum [ "off" ]) ]);
        default = null;
      };
    }; });
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
    ownerDisplay = lib.mkOption {
      type = t.nullOr (t.enum [ "raw" "hash" ]);
      default = null;
    };
    ownerDisplaySecret = lib.mkOption {
      type = t.nullOr (t.str);
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
    useAccessGroups = lib.mkOption {
      type = t.nullOr (t.bool);
      default = null;
    };
  }; });
    default = null;
  };

  commitments = lib.mkOption {
    type = t.nullOr (t.submodule { options = {
    enabled = lib.mkOption {
      type = t.nullOr (t.bool);
      default = null;
    };
    maxPerDay = lib.mkOption {
      type = t.nullOr (t.int);
      default = null;
    };
  }; });
    default = null;
  };

  crestodian = lib.mkOption {
    type = t.nullOr (t.submodule { options = {
    rescue = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      enabled = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.enum [ "auto" ]) (t.bool) ]);
        default = null;
      };
      ownerDmOnly = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      pendingTtlMinutes = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
    }; });
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
    }; });
      default = null;
    };
    failureDestination = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      accountId = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      channel = lib.mkOption {
        type = t.nullOr (t.str);
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
    maxConcurrentRuns = lib.mkOption {
      type = t.nullOr (t.int);
      default = null;
    };
    retry = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      backoffMs = lib.mkOption {
        type = t.nullOr (t.listOf (t.int));
        default = null;
      };
      maxAttempts = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      retryOn = lib.mkOption {
        type = t.nullOr (t.listOf (t.enum [ "rate_limit" "overloaded" "network" "timeout" "server_error" ]));
        default = null;
      };
    }; });
      default = null;
    };
    runLog = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      keepLines = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      maxBytes = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.str) (t.number) ]);
        default = null;
      };
    }; });
      default = null;
    };
    sessionRetention = lib.mkOption {
      type = t.nullOr (t.oneOf [ (t.str) (t.enum [ false ]) ]);
      default = null;
    };
    store = lib.mkOption {
      type = t.nullOr (t.str);
      default = null;
    };
    webhook = lib.mkOption {
      type = t.nullOr (t.str);
      default = null;
    };
    webhookToken = lib.mkOption {
      type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
      source = lib.mkOption {
        type = t.enum [ "env" "file" "exec" ];
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

  diagnostics = lib.mkOption {
    type = t.nullOr (t.submodule { options = {
    cacheTrace = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      enabled = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      filePath = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      includeMessages = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      includePrompt = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      includeSystem = lib.mkOption {
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
    memoryPressureSnapshot = lib.mkOption {
      type = t.nullOr (t.bool);
      default = null;
    };
    otel = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      captureContent = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.bool) (t.submodule { options = {
        enabled = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
        inputMessages = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
        outputMessages = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
        systemPrompt = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
        toolDefinitions = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
        toolInputs = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
        toolOutputs = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
      }; }) ]);
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
      metrics = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      metricsEndpoint = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      protocol = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.enum [ "http/protobuf" ]) (t.enum [ "grpc" ]) ]);
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
    stuckSessionAbortMs = lib.mkOption {
      type = t.nullOr (t.int);
      default = null;
    };
    stuckSessionWarnMs = lib.mkOption {
      type = t.nullOr (t.int);
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
      mode = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.enum [ "none" ]) (t.enum [ "token" ]) (t.enum [ "password" ]) (t.enum [ "trusted-proxy" ]) ]);
        default = null;
      };
      password = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
        source = lib.mkOption {
          type = t.enum [ "env" "file" "exec" ];
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
          type = t.enum [ "env" "file" "exec" ];
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
    channelHealthCheckMinutes = lib.mkOption {
      type = t.nullOr (t.int);
      default = null;
    };
    channelMaxRestartsPerHour = lib.mkOption {
      type = t.nullOr (t.int);
      default = null;
    };
    channelStaleEventThresholdMinutes = lib.mkOption {
      type = t.nullOr (t.int);
      default = null;
    };
    controlUi = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      allowExternalEmbedUrls = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      allowInsecureAuth = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      allowedOrigins = lib.mkOption {
        type = t.nullOr (t.listOf (t.str));
        default = null;
      };
      basePath = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      chatMessageMaxWidth = lib.mkOption {
        type = t.nullOr (t.anything);
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
      root = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
    }; });
      default = null;
    };
    customBindHost = lib.mkOption {
      type = t.nullOr (t.str);
      default = null;
    };
    handshakeTimeoutMs = lib.mkOption {
      type = t.nullOr (t.int);
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
          maxBodyBytes = lib.mkOption {
            type = t.nullOr (t.int);
            default = null;
          };
          maxImageParts = lib.mkOption {
            type = t.nullOr (t.int);
            default = null;
          };
          maxTotalImageBytes = lib.mkOption {
            type = t.nullOr (t.int);
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
          maxBodyBytes = lib.mkOption {
            type = t.nullOr (t.int);
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
      allowCommands = lib.mkOption {
        type = t.nullOr (t.listOf (t.str));
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
      denyCommands = lib.mkOption {
        type = t.nullOr (t.listOf (t.str));
        default = null;
      };
      pairing = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        autoApproveCidrs = lib.mkOption {
          type = t.nullOr (t.listOf (t.str));
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
      debounceMs = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      deferralTimeoutMs = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      mode = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.enum [ "off" ]) (t.enum [ "restart" ]) (t.enum [ "hot" ]) (t.enum [ "hybrid" ]) ]);
        default = null;
      };
    }; });
      default = null;
    };
    remote = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      enabled = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      password = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
        source = lib.mkOption {
          type = t.enum [ "env" "file" "exec" ];
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
          type = t.enum [ "env" "file" "exec" ];
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
      resetOnExit = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      serviceName = lib.mkOption {
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
      handlers = lib.mkOption {
        type = t.nullOr (t.listOf (t.submodule { options = {
        event = lib.mkOption {
          type = t.str;
        };
        export = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        module = lib.mkOption {
          type = t.str;
        };
      }; }));
        default = null;
      };
      installs = lib.mkOption {
        type = t.nullOr (t.attrsOf (t.submodule { options = {
        artifactFormat = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.enum [ "zip" ]) (t.enum [ "tgz" ]) ]);
          default = null;
        };
        artifactKind = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.enum [ "legacy-zip" ]) (t.enum [ "npm-pack" ]) ]);
          default = null;
        };
        clawhubChannel = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.enum [ "official" ]) (t.enum [ "community" ]) (t.enum [ "private" ]) ]);
          default = null;
        };
        clawhubFamily = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.enum [ "code-plugin" ]) (t.enum [ "bundle-plugin" ]) ]);
          default = null;
        };
        clawhubPackage = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        clawhubUrl = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        clawpackManifestSha256 = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        clawpackSha256 = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        clawpackSize = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        clawpackSpecVersion = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        gitCommit = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        gitRef = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        gitUrl = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        hooks = lib.mkOption {
          type = t.nullOr (t.listOf (t.str));
          default = null;
        };
        installPath = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        installedAt = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        integrity = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        npmIntegrity = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        npmShasum = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        npmTarballName = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        resolvedAt = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        resolvedName = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        resolvedSpec = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        resolvedVersion = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        shasum = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        source = lib.mkOption {
          type = t.oneOf [ (t.enum [ "npm" ]) (t.enum [ "archive" ]) (t.enum [ "path" ]) (t.enum [ "clawhub" ]) (t.enum [ "git" ]) ];
        };
        sourcePath = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        spec = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        version = lib.mkOption {
          type = t.nullOr (t.str);
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
    maxBodyBytes = lib.mkOption {
      type = t.nullOr (t.int);
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
    consoleLevel = lib.mkOption {
      type = t.nullOr (t.oneOf [ (t.enum [ "silent" ]) (t.enum [ "fatal" ]) (t.enum [ "error" ]) (t.enum [ "warn" ]) (t.enum [ "info" ]) (t.enum [ "debug" ]) (t.enum [ "trace" ]) ]);
      default = null;
    };
    consoleStyle = lib.mkOption {
      type = t.nullOr (t.oneOf [ (t.enum [ "pretty" ]) (t.enum [ "compact" ]) (t.enum [ "json" ]) ]);
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
    redactSensitive = lib.mkOption {
      type = t.nullOr (t.oneOf [ (t.enum [ "off" ]) (t.enum [ "tools" ]) ]);
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
      client_cert = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      client_key = lib.mkOption {
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
        default_tools_approval_mode = lib.mkOption {
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
      connectTimeout = lib.mkOption {
        type = t.nullOr (t.number);
        default = null;
      };
      connect_timeout = lib.mkOption {
        type = t.nullOr (t.number);
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
        clientMetadataUrl = lib.mkOption {
          type = t.nullOr (t.str);
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
      ssl_verify = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      supportsParallelToolCalls = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      supports_parallel_tool_calls = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      timeout = lib.mkOption {
        type = t.nullOr (t.number);
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
        type = t.nullOr (t.oneOf [ (t.enum [ "sse" ]) (t.enum [ "streamable-http" ]) ]);
        default = null;
      };
      url = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      workingDirectory = lib.mkOption {
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

  media = lib.mkOption {
    type = t.nullOr (t.submodule { options = {
    preserveFilenames = lib.mkOption {
      type = t.nullOr (t.bool);
      default = null;
    };
    ttlHours = lib.mkOption {
      type = t.nullOr (t.int);
      default = null;
    };
  }; });
    default = null;
  };

  memory = lib.mkOption {
    type = t.nullOr (t.submodule { options = {
    backend = lib.mkOption {
      type = t.nullOr (t.oneOf [ (t.enum [ "builtin" ]) (t.enum [ "qmd" ]) ]);
      default = null;
    };
    citations = lib.mkOption {
      type = t.nullOr (t.oneOf [ (t.enum [ "auto" ]) (t.enum [ "on" ]) (t.enum [ "off" ]) ]);
      default = null;
    };
    qmd = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      command = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      includeDefaultMemory = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      limits = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        maxInjectedChars = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        maxResults = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        maxSnippetChars = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        timeoutMs = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
      }; });
        default = null;
      };
      mcporter = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        enabled = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
        serverName = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        startDaemon = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
      }; });
        default = null;
      };
      paths = lib.mkOption {
        type = t.nullOr (t.listOf (t.submodule { options = {
        name = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        path = lib.mkOption {
          type = t.str;
        };
        pattern = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
      }; }));
        default = null;
      };
      rerank = lib.mkOption {
        type = t.nullOr (t.bool);
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
              type = t.nullOr (t.oneOf [ (t.enum [ "direct" ]) (t.enum [ "group" ]) (t.enum [ "channel" ]) (t.enum [ "dm" ]) ]);
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
      searchMode = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.enum [ "query" ]) (t.enum [ "search" ]) (t.enum [ "vsearch" ]) ]);
        default = null;
      };
      searchTool = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      sessions = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        enabled = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
        exportDir = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        retentionDays = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
      }; });
        default = null;
      };
      update = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        commandTimeoutMs = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        debounceMs = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        embedInterval = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        embedTimeoutMs = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        interval = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        onBoot = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
        startup = lib.mkOption {
          type = t.nullOr (t.enum [ "off" "idle" "immediate" ]);
          default = null;
        };
        startupDelayMs = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        updateTimeoutMs = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        waitForBootSync = lib.mkOption {
          type = t.nullOr (t.bool);
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
    messagePrefix = lib.mkOption {
      type = t.nullOr (t.str);
      default = null;
    };
    queue = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      byChannel = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        discord = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.enum [ "steer" ]) (t.enum [ "followup" ]) (t.enum [ "collect" ]) (t.enum [ "interrupt" ]) ]);
          default = null;
        };
        googlechat = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.enum [ "steer" ]) (t.enum [ "followup" ]) (t.enum [ "collect" ]) (t.enum [ "interrupt" ]) ]);
          default = null;
        };
        imessage = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.enum [ "steer" ]) (t.enum [ "followup" ]) (t.enum [ "collect" ]) (t.enum [ "interrupt" ]) ]);
          default = null;
        };
        irc = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.enum [ "steer" ]) (t.enum [ "followup" ]) (t.enum [ "collect" ]) (t.enum [ "interrupt" ]) ]);
          default = null;
        };
        matrix = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.enum [ "steer" ]) (t.enum [ "followup" ]) (t.enum [ "collect" ]) (t.enum [ "interrupt" ]) ]);
          default = null;
        };
        mattermost = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.enum [ "steer" ]) (t.enum [ "followup" ]) (t.enum [ "collect" ]) (t.enum [ "interrupt" ]) ]);
          default = null;
        };
        msteams = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.enum [ "steer" ]) (t.enum [ "followup" ]) (t.enum [ "collect" ]) (t.enum [ "interrupt" ]) ]);
          default = null;
        };
        signal = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.enum [ "steer" ]) (t.enum [ "followup" ]) (t.enum [ "collect" ]) (t.enum [ "interrupt" ]) ]);
          default = null;
        };
        slack = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.enum [ "steer" ]) (t.enum [ "followup" ]) (t.enum [ "collect" ]) (t.enum [ "interrupt" ]) ]);
          default = null;
        };
        telegram = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.enum [ "steer" ]) (t.enum [ "followup" ]) (t.enum [ "collect" ]) (t.enum [ "interrupt" ]) ]);
          default = null;
        };
        webchat = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.enum [ "steer" ]) (t.enum [ "followup" ]) (t.enum [ "collect" ]) (t.enum [ "interrupt" ]) ]);
          default = null;
        };
        whatsapp = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.enum [ "steer" ]) (t.enum [ "followup" ]) (t.enum [ "collect" ]) (t.enum [ "interrupt" ]) ]);
          default = null;
        };
      }; });
        default = null;
      };
      cap = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      debounceMs = lib.mkOption {
        type = t.nullOr (t.int);
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
    removeAckAfterReply = lib.mkOption {
      type = t.nullOr (t.bool);
      default = null;
    };
    responsePrefix = lib.mkOption {
      type = t.nullOr (t.str);
      default = null;
    };
    statusReactions = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      emojis = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        build = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        coding = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        compacting = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        concierge = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        deploy = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        done = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        error = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        stallHard = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        stallSoft = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        thinking = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        tool = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        web = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
      }; });
        default = null;
      };
      enabled = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      timing = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        debounceMs = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        doneHoldMs = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        errorHoldMs = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        stallHardMs = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        stallSoftMs = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
      }; });
        default = null;
      };
    }; });
      default = null;
    };
    suppressToolErrors = lib.mkOption {
      type = t.nullOr (t.bool);
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
        prompt = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          accent = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          constraints = lib.mkOption {
            type = t.nullOr (t.listOf (t.str));
            default = null;
          };
          pacing = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          profile = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          sampleContext = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          scene = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
          style = lib.mkOption {
            type = t.nullOr (t.str);
            default = null;
          };
        }; });
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
              type = t.enum [ "env" "file" "exec" ];
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
            type = t.enum [ "env" "file" "exec" ];
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
    lastTouchedAt = lib.mkOption {
      type = t.nullOr (t.str);
      default = null;
    };
    lastTouchedVersion = lib.mkOption {
      type = t.nullOr (t.str);
      default = null;
    };
  }; });
    default = null;
  };

  models = lib.mkOption {
    type = t.nullOr (t.submodule { options = {
    mode = lib.mkOption {
      type = t.nullOr (t.oneOf [ (t.enum [ "merge" ]) (t.enum [ "replace" ]) ]);
      default = null;
    };
    pricing = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      enabled = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
    }; });
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
        type = t.nullOr (t.enum [ "openai-completions" "openai-responses" "openai-chatgpt-responses" "anthropic-messages" "google-generative-ai" "google-vertex" "github-copilot" "bedrock-converse-stream" "ollama" "azure-openai-responses" ]);
        default = null;
      };
      apiKey = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
        source = lib.mkOption {
          type = t.enum [ "env" "file" "exec" ];
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
      contextTokens = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      contextWindow = lib.mkOption {
        type = t.nullOr (t.number);
        default = null;
      };
      headers = lib.mkOption {
        type = t.nullOr (t.attrsOf (t.oneOf [ (t.str) (t.submodule { options = {
        source = lib.mkOption {
          type = t.enum [ "env" "file" "exec" ];
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
          type = t.nullOr (t.enum [ "openai-completions" "openai-responses" "openai-chatgpt-responses" "anthropic-messages" "google-generative-ai" "google-vertex" "github-copilot" "bedrock-converse-stream" "ollama" "azure-openai-responses" ]);
          default = null;
        };
        baseUrl = lib.mkOption {
          type = t.nullOr (t.str);
          default = null;
        };
        compat = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          maxTokensField = lib.mkOption {
            type = t.nullOr (t.oneOf [ (t.enum [ "max_completion_tokens" ]) (t.enum [ "max_tokens" ]) ]);
            default = null;
          };
          nativeWebSearchTool = lib.mkOption {
            type = t.nullOr (t.bool);
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
          requiresMistralToolIds = lib.mkOption {
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
          supportsPromptCacheKey = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          supportsReasoningEffort = lib.mkOption {
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
          visibleReasoningDetailTypes = lib.mkOption {
            type = t.nullOr (t.listOf (t.str));
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
              type = t.enum [ "env" "file" "exec" ];
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
              type = t.enum [ "env" "file" "exec" ];
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
            type = t.enum [ "env" "file" "exec" ];
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
                type = t.enum [ "env" "file" "exec" ];
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
                type = t.enum [ "env" "file" "exec" ];
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
                type = t.enum [ "env" "file" "exec" ];
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
                type = t.enum [ "env" "file" "exec" ];
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
                type = t.enum [ "env" "file" "exec" ];
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
                type = t.enum [ "env" "file" "exec" ];
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
                type = t.enum [ "env" "file" "exec" ];
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
                type = t.enum [ "env" "file" "exec" ];
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
              type = t.enum [ "env" "file" "exec" ];
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
              type = t.enum [ "env" "file" "exec" ];
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
              type = t.enum [ "env" "file" "exec" ];
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
              type = t.enum [ "env" "file" "exec" ];
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
  }; });
    default = null;
  };

  plugins = lib.mkOption {
    type = t.nullOr (t.submodule { options = {
    allow = lib.mkOption {
      type = t.nullOr (t.listOf (t.str));
      default = null;
    };
    bundledDiscovery = lib.mkOption {
      type = t.nullOr (t.enum [ "compat" "allowlist" ]);
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
    }; });
      default = null;
    };
    providers = lib.mkOption {
      type = t.nullOr (t.attrsOf (t.submodule { options = {
      source = lib.mkOption {
        type = t.enum [ "env" "file" "exec" ];
      };
      allowInsecurePath = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      allowlist = lib.mkOption {
        type = t.nullOr (t.listOf (t.str));
        default = null;
      };
      allowSymlinkCommand = lib.mkOption {
        type = t.nullOr (t.bool);
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
    resolution = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      maxBatchBytes = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      maxProviderConcurrency = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      maxRefsPerProvider = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
    }; });
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
        allowInsecurePath = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
        allowSymlinkCommand = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
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
    agentToAgent = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      maxPingPongTurns = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
    }; });
      default = null;
    };
    dmScope = lib.mkOption {
      type = t.nullOr (t.oneOf [ (t.enum [ "main" ]) (t.enum [ "per-peer" ]) (t.enum [ "per-channel-peer" ]) (t.enum [ "per-account-channel-peer" ]) ]);
      default = null;
    };
    identityLinks = lib.mkOption {
      type = t.nullOr (t.attrsOf (t.listOf (t.str)));
      default = null;
    };
    idleMinutes = lib.mkOption {
      type = t.nullOr (t.int);
      default = null;
    };
    mainKey = lib.mkOption {
      type = t.nullOr (t.str);
      default = null;
    };
    maintenance = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      highWaterBytes = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.str) (t.number) ]);
        default = null;
      };
      maxDiskBytes = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.str) (t.number) ]);
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
      pruneAfter = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.str) (t.number) ]);
        default = null;
      };
      pruneDays = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      resetArchiveRetention = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.str) (t.number) (t.enum [ false ]) ]);
        default = null;
      };
      rotateBytes = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.str) (t.number) ]);
        default = null;
      };
    }; });
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
        type = t.nullOr (t.oneOf [ (t.enum [ "daily" ]) (t.enum [ "idle" ]) ]);
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
        type = t.nullOr (t.oneOf [ (t.enum [ "daily" ]) (t.enum [ "idle" ]) ]);
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
          type = t.nullOr (t.oneOf [ (t.enum [ "daily" ]) (t.enum [ "idle" ]) ]);
          default = null;
        };
      }; });
        default = null;
      };
      dm = lib.mkOption {
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
          type = t.nullOr (t.oneOf [ (t.enum [ "daily" ]) (t.enum [ "idle" ]) ]);
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
          type = t.nullOr (t.oneOf [ (t.enum [ "daily" ]) (t.enum [ "idle" ]) ]);
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
          type = t.nullOr (t.oneOf [ (t.enum [ "daily" ]) (t.enum [ "idle" ]) ]);
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
            type = t.nullOr (t.oneOf [ (t.enum [ "direct" ]) (t.enum [ "group" ]) (t.enum [ "channel" ]) (t.enum [ "dm" ]) ]);
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
    typingIntervalSeconds = lib.mkOption {
      type = t.nullOr (t.int);
      default = null;
    };
    typingMode = lib.mkOption {
      type = t.nullOr (t.oneOf [ (t.enum [ "never" ]) (t.enum [ "instant" ]) (t.enum [ "thinking" ]) (t.enum [ "message" ]) ]);
      default = null;
    };
    writeLock = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      acquireTimeoutMs = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      maxHoldMs = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      staleMs = lib.mkOption {
        type = t.nullOr (t.int);
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
          type = t.enum [ "env" "file" "exec" ];
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
      watchDebounceMs = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
    }; });
      default = null;
    };
    workshop = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      allowSymlinkTargetWrites = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      approvalPolicy = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.enum [ "pending" ]) (t.enum [ "auto" ]) ]);
        default = null;
      };
      autonomous = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        enabled = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
      }; });
        default = null;
      };
      maxPending = lib.mkOption {
        type = t.nullOr (t.int);
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

  surfaces = lib.mkOption {
    type = t.nullOr (t.attrsOf (t.submodule { options = {
    silentReply = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      group = lib.mkOption {
        type = t.nullOr (t.oneOf [ (t.enum [ "allow" ]) (t.enum [ "disallow" ]) ]);
        default = null;
      };
      internal = lib.mkOption {
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
    consultFastMode = lib.mkOption {
      type = t.nullOr (t.bool);
      default = null;
    };
    consultThinkingLevel = lib.mkOption {
      type = t.nullOr (t.enum [ "off" "minimal" "low" "medium" "high" "xhigh" "adaptive" "max" ]);
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
          type = t.enum [ "env" "file" "exec" ];
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
      provider = lib.mkOption {
        type = t.nullOr (t.str);
        default = null;
      };
      providers = lib.mkOption {
        type = t.nullOr (t.attrsOf (t.submodule { options = {
        apiKey = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
          source = lib.mkOption {
            type = t.enum [ "env" "file" "exec" ];
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
      voice = lib.mkOption {
        type = t.nullOr (t.str);
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
      type = t.nullOr (t.oneOf [ (t.bool) (t.submodule { options = {
      enabled = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      languages = lib.mkOption {
        type = t.nullOr (t.listOf (t.enum [ "javascript" "typescript" ]));
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
      runtime = lib.mkOption {
        type = t.nullOr (t.enum [ "quickjs-wasi" ]);
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
      timeoutSec = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
    }; });
      default = null;
    };
    experimental = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      planTool = lib.mkOption {
        type = t.nullOr (t.bool);
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
              type = t.nullOr (t.oneOf [ (t.enum [ "direct" ]) (t.enum [ "group" ]) (t.enum [ "channel" ]) (t.enum [ "dm" ]) ]);
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
      criticalThreshold = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      detectors = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        genericRepeat = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
        knownPollNoProgress = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
        pingPong = lib.mkOption {
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
      globalCircuitBreakerThreshold = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      historySize = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      postCompactionGuard = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        windowSize = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
      }; });
        default = null;
      };
      unknownToolThreshold = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      warningThreshold = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
    }; });
      default = null;
    };
    media = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      asyncCompletion = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        directSend = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
      }; });
        default = null;
      };
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
        deepgram = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          detectLanguage = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          punctuate = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          smartFormat = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
        }; });
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
          deepgram = lib.mkOption {
            type = t.nullOr (t.submodule { options = {
            detectLanguage = lib.mkOption {
              type = t.nullOr (t.bool);
              default = null;
            };
            punctuate = lib.mkOption {
              type = t.nullOr (t.bool);
              default = null;
            };
            smartFormat = lib.mkOption {
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
                  type = t.enum [ "env" "file" "exec" ];
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
                  type = t.enum [ "env" "file" "exec" ];
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
                type = t.enum [ "env" "file" "exec" ];
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
                    type = t.enum [ "env" "file" "exec" ];
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
                    type = t.enum [ "env" "file" "exec" ];
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
                    type = t.enum [ "env" "file" "exec" ];
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
                    type = t.enum [ "env" "file" "exec" ];
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
                    type = t.enum [ "env" "file" "exec" ];
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
                    type = t.enum [ "env" "file" "exec" ];
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
                    type = t.enum [ "env" "file" "exec" ];
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
                    type = t.enum [ "env" "file" "exec" ];
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
                  type = t.enum [ "env" "file" "exec" ];
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
                  type = t.enum [ "env" "file" "exec" ];
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
                  type = t.enum [ "env" "file" "exec" ];
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
                  type = t.enum [ "env" "file" "exec" ];
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
                type = t.enum [ "env" "file" "exec" ];
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
                type = t.enum [ "env" "file" "exec" ];
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
              type = t.enum [ "env" "file" "exec" ];
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
                  type = t.enum [ "env" "file" "exec" ];
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
                  type = t.enum [ "env" "file" "exec" ];
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
                  type = t.enum [ "env" "file" "exec" ];
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
                  type = t.enum [ "env" "file" "exec" ];
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
                  type = t.enum [ "env" "file" "exec" ];
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
                  type = t.enum [ "env" "file" "exec" ];
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
                  type = t.enum [ "env" "file" "exec" ];
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
                  type = t.enum [ "env" "file" "exec" ];
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
                type = t.enum [ "env" "file" "exec" ];
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
                type = t.enum [ "env" "file" "exec" ];
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
                type = t.enum [ "env" "file" "exec" ];
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
                type = t.enum [ "env" "file" "exec" ];
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
                type = t.nullOr (t.oneOf [ (t.enum [ "direct" ]) (t.enum [ "group" ]) (t.enum [ "channel" ]) (t.enum [ "dm" ]) ]);
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
        deepgram = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          detectLanguage = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          punctuate = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          smartFormat = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
        }; });
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
          deepgram = lib.mkOption {
            type = t.nullOr (t.submodule { options = {
            detectLanguage = lib.mkOption {
              type = t.nullOr (t.bool);
              default = null;
            };
            punctuate = lib.mkOption {
              type = t.nullOr (t.bool);
              default = null;
            };
            smartFormat = lib.mkOption {
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
                  type = t.enum [ "env" "file" "exec" ];
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
                  type = t.enum [ "env" "file" "exec" ];
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
                type = t.enum [ "env" "file" "exec" ];
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
                    type = t.enum [ "env" "file" "exec" ];
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
                    type = t.enum [ "env" "file" "exec" ];
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
                    type = t.enum [ "env" "file" "exec" ];
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
                    type = t.enum [ "env" "file" "exec" ];
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
                    type = t.enum [ "env" "file" "exec" ];
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
                    type = t.enum [ "env" "file" "exec" ];
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
                    type = t.enum [ "env" "file" "exec" ];
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
                    type = t.enum [ "env" "file" "exec" ];
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
                  type = t.enum [ "env" "file" "exec" ];
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
                  type = t.enum [ "env" "file" "exec" ];
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
                  type = t.enum [ "env" "file" "exec" ];
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
                  type = t.enum [ "env" "file" "exec" ];
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
                type = t.enum [ "env" "file" "exec" ];
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
                type = t.enum [ "env" "file" "exec" ];
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
              type = t.enum [ "env" "file" "exec" ];
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
                  type = t.enum [ "env" "file" "exec" ];
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
                  type = t.enum [ "env" "file" "exec" ];
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
                  type = t.enum [ "env" "file" "exec" ];
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
                  type = t.enum [ "env" "file" "exec" ];
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
                  type = t.enum [ "env" "file" "exec" ];
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
                  type = t.enum [ "env" "file" "exec" ];
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
                  type = t.enum [ "env" "file" "exec" ];
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
                  type = t.enum [ "env" "file" "exec" ];
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
                type = t.enum [ "env" "file" "exec" ];
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
                type = t.enum [ "env" "file" "exec" ];
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
                type = t.enum [ "env" "file" "exec" ];
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
                type = t.enum [ "env" "file" "exec" ];
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
                type = t.nullOr (t.oneOf [ (t.enum [ "direct" ]) (t.enum [ "group" ]) (t.enum [ "channel" ]) (t.enum [ "dm" ]) ]);
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
        deepgram = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          detectLanguage = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          punctuate = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          smartFormat = lib.mkOption {
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
                type = t.enum [ "env" "file" "exec" ];
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
                type = t.enum [ "env" "file" "exec" ];
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
              type = t.enum [ "env" "file" "exec" ];
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
                  type = t.enum [ "env" "file" "exec" ];
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
                  type = t.enum [ "env" "file" "exec" ];
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
                  type = t.enum [ "env" "file" "exec" ];
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
                  type = t.enum [ "env" "file" "exec" ];
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
                  type = t.enum [ "env" "file" "exec" ];
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
                  type = t.enum [ "env" "file" "exec" ];
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
                  type = t.enum [ "env" "file" "exec" ];
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
                  type = t.enum [ "env" "file" "exec" ];
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
                type = t.enum [ "env" "file" "exec" ];
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
                type = t.enum [ "env" "file" "exec" ];
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
                type = t.enum [ "env" "file" "exec" ];
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
                type = t.enum [ "env" "file" "exec" ];
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
        deepgram = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          detectLanguage = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          punctuate = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          smartFormat = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
        }; });
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
          deepgram = lib.mkOption {
            type = t.nullOr (t.submodule { options = {
            detectLanguage = lib.mkOption {
              type = t.nullOr (t.bool);
              default = null;
            };
            punctuate = lib.mkOption {
              type = t.nullOr (t.bool);
              default = null;
            };
            smartFormat = lib.mkOption {
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
                  type = t.enum [ "env" "file" "exec" ];
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
                  type = t.enum [ "env" "file" "exec" ];
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
                type = t.enum [ "env" "file" "exec" ];
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
                    type = t.enum [ "env" "file" "exec" ];
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
                    type = t.enum [ "env" "file" "exec" ];
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
                    type = t.enum [ "env" "file" "exec" ];
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
                    type = t.enum [ "env" "file" "exec" ];
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
                    type = t.enum [ "env" "file" "exec" ];
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
                    type = t.enum [ "env" "file" "exec" ];
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
                    type = t.enum [ "env" "file" "exec" ];
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
                    type = t.enum [ "env" "file" "exec" ];
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
                  type = t.enum [ "env" "file" "exec" ];
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
                  type = t.enum [ "env" "file" "exec" ];
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
                  type = t.enum [ "env" "file" "exec" ];
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
                  type = t.enum [ "env" "file" "exec" ];
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
                type = t.enum [ "env" "file" "exec" ];
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
                type = t.enum [ "env" "file" "exec" ];
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
              type = t.enum [ "env" "file" "exec" ];
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
                  type = t.enum [ "env" "file" "exec" ];
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
                  type = t.enum [ "env" "file" "exec" ];
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
                  type = t.enum [ "env" "file" "exec" ];
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
                  type = t.enum [ "env" "file" "exec" ];
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
                  type = t.enum [ "env" "file" "exec" ];
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
                  type = t.enum [ "env" "file" "exec" ];
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
                  type = t.enum [ "env" "file" "exec" ];
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
                  type = t.enum [ "env" "file" "exec" ];
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
                type = t.enum [ "env" "file" "exec" ];
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
                type = t.enum [ "env" "file" "exec" ];
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
                type = t.enum [ "env" "file" "exec" ];
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
                type = t.enum [ "env" "file" "exec" ];
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
                type = t.nullOr (t.oneOf [ (t.enum [ "direct" ]) (t.enum [ "group" ]) (t.enum [ "channel" ]) (t.enum [ "dm" ]) ]);
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
      allowCrossContextSend = lib.mkOption {
        type = t.nullOr (t.bool);
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
    toolSearch = lib.mkOption {
      type = t.nullOr (t.oneOf [ (t.bool) (t.submodule { options = {
      codeTimeoutMs = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      enabled = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      maxSearchLimit = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      mode = lib.mkOption {
        type = t.nullOr (t.enum [ "code" "tools" "directory" ]);
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
        firecrawl = lib.mkOption {
          type = t.nullOr (t.submodule { options = {
          apiKey = lib.mkOption {
            type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
            source = lib.mkOption {
              type = t.enum [ "env" "file" "exec" ];
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
          enabled = lib.mkOption {
            type = t.nullOr (t.bool);
            default = null;
          };
          maxAgeMs = lib.mkOption {
            type = t.nullOr (t.int);
            default = null;
          };
          onlyMainContent = lib.mkOption {
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
        apiKey = lib.mkOption {
          type = t.nullOr (t.oneOf [ (t.str) (t.submodule { options = {
          source = lib.mkOption {
            type = t.enum [ "env" "file" "exec" ];
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
      x_search = lib.mkOption {
        type = t.nullOr (t.submodule { options = {
        cacheTtlMinutes = lib.mkOption {
          type = t.nullOr (t.number);
          default = null;
        };
        enabled = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
        inlineCitations = lib.mkOption {
          type = t.nullOr (t.bool);
          default = null;
        };
        maxTurns = lib.mkOption {
          type = t.nullOr (t.int);
          default = null;
        };
        model = lib.mkOption {
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
    }; }));
      default = null;
    };
    enabled = lib.mkOption {
      type = t.nullOr (t.bool);
      default = null;
    };
    maxUtterances = lib.mkOption {
      type = t.nullOr (t.int);
      default = null;
    };
  }; });
    default = null;
  };

  tui = lib.mkOption {
    type = t.nullOr (t.submodule { options = {
    footer = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      showRemoteHost = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
    }; });
      default = null;
    };
  }; });
    default = null;
  };

  ui = lib.mkOption {
    type = t.nullOr (t.submodule { options = {
    assistant = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      avatar = lib.mkOption {
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
      betaCheckIntervalHours = lib.mkOption {
        type = t.nullOr (t.number);
        default = null;
      };
      enabled = lib.mkOption {
        type = t.nullOr (t.bool);
        default = null;
      };
      stableDelayHours = lib.mkOption {
        type = t.nullOr (t.number);
        default = null;
      };
      stableJitterHours = lib.mkOption {
        type = t.nullOr (t.number);
        default = null;
      };
    }; });
      default = null;
    };
    channel = lib.mkOption {
      type = t.nullOr (t.oneOf [ (t.enum [ "stable" ]) (t.enum [ "beta" ]) (t.enum [ "dev" ]) ]);
      default = null;
    };
    checkOnStart = lib.mkOption {
      type = t.nullOr (t.bool);
      default = null;
    };
  }; });
    default = null;
  };

  web = lib.mkOption {
    type = t.nullOr (t.submodule { options = {
    enabled = lib.mkOption {
      type = t.nullOr (t.bool);
      default = null;
    };
    heartbeatSeconds = lib.mkOption {
      type = t.nullOr (t.int);
      default = null;
    };
    reconnect = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      factor = lib.mkOption {
        type = t.nullOr (t.number);
        default = null;
      };
      initialMs = lib.mkOption {
        type = t.nullOr (t.number);
        default = null;
      };
      jitter = lib.mkOption {
        type = t.nullOr (t.number);
        default = null;
      };
      maxAttempts = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      maxMs = lib.mkOption {
        type = t.nullOr (t.number);
        default = null;
      };
    }; });
      default = null;
    };
    whatsapp = lib.mkOption {
      type = t.nullOr (t.submodule { options = {
      connectTimeoutMs = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      defaultQueryTimeoutMs = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
      keepAliveIntervalMs = lib.mkOption {
        type = t.nullOr (t.int);
        default = null;
      };
    }; });
      default = null;
    };
  }; });
    default = null;
  };

  wizard = lib.mkOption {
    type = t.nullOr (t.submodule { options = {
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
  }; });
    default = null;
  };
}
