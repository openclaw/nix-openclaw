{ lib, explicitOwnership }:

let
  authoredRosterCases = [
    { entries.writer = { }; }
    { entries.Writer = { }; }
    { entries."_worker-1" = { }; }
    { entries."${lib.concatStrings (lib.replicate 64 "a")}" = { }; }
    {
      ownership = "explicit";
      entries = { };
    }
    { ownership = "explicit"; }
    {
      entries = {
        writer = { };
        research = { };
      };
    }
    (
      explicitOwnership
      // {
        entries = {
          writer = { };
          research = { };
        };
      }
    )
  ];

  canonicalAgentIdCases = [
    {
      entries."_worker--" = { };
      expected = [ "_worker" ];
    }
    {
      entries."_worker-" = { };
      expected = [ "_worker" ];
    }
    {
      entries."_Worker--" = { };
      expected = [ "_worker" ];
    }
    {
      entries."_worker-1" = { };
      expected = [ "_worker-1" ];
    }
    {
      entries."_worker-_" = { };
      expected = [ "_worker-_" ];
    }
    {
      entries."_" = { };
      expected = [ "_" ];
    }
    {
      entries."__" = { };
      expected = [ "__" ];
    }
    {
      entries."_--" = { };
      expected = [ "_" ];
    }
    {
      entries."_-" = { };
      expected = [ "_" ];
    }
    {
      entries."__--" = { };
      expected = [ "__" ];
    }
    {
      entries."_A-B--" = { };
      expected = [ "_a-b" ];
    }
    {
      entries = {
        worker = { };
        "worker-" = { };
      };
      expected = [
        "worker"
        "worker-"
      ];
    }
    {
      entries."_${lib.concatStrings (lib.replicate 63 "-")}" = { };
      expected = [ "_" ];
    }
    {
      entries.Writer = { };
      expected = [ "writer" ];
    }
    {
      entries."0--" = { };
      expected = [ "0--" ];
    }
    {
      entries = {
        a = { };
        "a--" = { };
      };
      expected = [
        "a"
        "a--"
      ];
    }
  ];

in
{
  inherit authoredRosterCases canonicalAgentIdCases;
}
