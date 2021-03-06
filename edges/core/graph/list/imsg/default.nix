{ edge, edges }:

edge {
  src = ./.;
  edges =  with edges; [ core_graph_imsg ];
  schema = with edges; ''
    @0xb3261aab60f342e2;

    using CoreGraphImsg = import "${core_graph_imsg}/src/edge.capnp";

    struct CoreGraphListImsg {
      list @0 : List(CoreGraphImsg.CoreGraphImsg);
    }
  '';
}
