{ agent, edges, crates, pkgs }:

agent {
  src = ./.;
  edges = with edges; [ prim_u64 ];
  crates = with crates; [ rustfbp capnp ];
  osdeps = with pkgs; [];
}
