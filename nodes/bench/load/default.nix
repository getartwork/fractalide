{ subgraph, nodes, edges }:

subgraph {
 src = ./.;
 flowscript = with nodes; with edges; ''
 inc1(${bench_inc_1000})
 inc1() output -> input inc2(${bench_inc_1000})
 inc2() output -> input inc3(${bench_inc_1000})
 inc3() output -> input inc4(${bench_inc_1000})
 inc4() output -> input inc5(${bench_inc_1000})
 inc5() output -> input inc6(${bench_inc_1000})
 inc6() output -> input inc7(${bench_inc_1000})
 inc7() output -> input inc8(${bench_inc_1000})
 inc8() output -> input inc9(${bench_inc_1000})
 inc9() output -> input inc10(${bench_inc_1000})
 '';
}
