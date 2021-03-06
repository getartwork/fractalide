{ edge, edges }:

edge {
  src = ./.;
  edges =  with edges; [];
  schema = with edges; ''
    @0x8c2b4d099863a589;
    # The Void type has exactly one possible value, and thus can be encoded in zero bits. It is rarely used, but can be useful as a union member.

    struct PrimVoid {
            void @0 :Void;
    }
  '';
}
