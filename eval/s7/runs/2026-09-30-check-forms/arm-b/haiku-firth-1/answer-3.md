### task: reverse
```firth
: fwd-build
  (forall ρ; ρ xs:Seq Int^many res:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { xs res i } {
    i xs prim seq-int.len prim >=
    [ res ] [
      res xs i prim seq-int.at prim seq-int.push
      locals { res } {
        xs res i 1 prim + fwd-build
      }
    ] if
  };

: rev-help
  (forall ρ; ρ xs:Seq Int^many res:Seq Int^many i:Int^many -- ρ reversed:Seq Int^many)
  locals { xs res i } {
    i 0 prim <
    [ res ] [
      res xs i prim seq-int.at prim seq-int.push
      locals { res } {
        res xs i 1 prim - rev-help
      }
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    xs prim seq-int.empty 0 fwd-build
    locals { forward } {
      forward prim seq-int.empty forward prim seq-int.len 1 prim - rev-help
    }
  };
```

### task: prefix-sums
```firth
: prefix-help
  (forall ρ; ρ xs:Seq Int^many res:Seq Int^many s:Int^many i:Int^many -- ρ sums:Seq Int^many)
  locals { xs res s i } {
    i xs prim seq-int.len prim >=
    [ res ] [
      xs i prim seq-int.at s prim +
      locals { newsum } {
        res newsum prim seq-int.push
        locals { res } {
          xs res newsum i 1 prim + prefix-help
        }
      }
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } {
    xs prim seq-int.empty 0 0 prefix-help
  };
```

### task: keep-positive
```firth
: keep-help
  (forall ρ; ρ xs:Seq Int^many res:Seq Int^many i:Int^many -- ρ positives:Seq Int^many)
  locals { xs res i } {
    i xs prim seq-int.len prim >=
    [ res ] [
      xs i prim seq-int.at
      locals { v } {
        v 0 prim >
        [ res v prim seq-int.push locals { res } { xs res i 1 prim + keep-help } ]
        [ xs res i 1 prim + keep-help ]
        if
      }
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } {
    xs prim seq-int.empty 0 keep-help
  };
```

### task: longest-run
```firth
: run-help
  (forall ρ; ρ xs:Seq Int^many cr:Int^many mr:Int^many i:Int^many -- ρ length:Int^many)
  locals { xs cr mr i } {
    i xs prim seq-int.len prim >=
    [ mr ] [
      i 0 prim =
      [ xs 1 mr i 1 prim + run-help ] [
        xs i prim seq-int.at
        xs i 1 prim - prim seq-int.at
        prim =
        [ cr 1 prim + ] [ 1 ] if
        locals { newcr } {
          newcr mr prim >
          [ xs newcr newcr i 1 prim + run-help ]
          [ xs newcr mr i 1 prim + run-help ]
          if
        }
      ] if
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } {
    xs 0 0 0 run-help
  };
```

### task: merge-sorted
```firth
: merge-help
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many res:Seq Int^many i:Int^many j:Int^many -- ρ merged:Seq Int^many)
  locals { xs ys res i j } {
    i xs prim seq-int.len prim >=
    [ j ys prim seq-int.len prim >=
      [ res ] [
        res ys j prim seq-int.at prim seq-int.push
        locals { res } {
          res xs ys i j 1 prim + merge-help
        }
      ] if
    ] [
      j ys prim seq-int.len prim >=
      [ res xs i prim seq-int.at prim seq-int.push
        locals { res } {
          res xs ys i 1 prim + j merge-help
        }
      ] [
        xs i prim seq-int.at ys j prim seq-int.at prim <=
        [ res xs i prim seq-int.at prim seq-int.push
          locals { res } {
            res xs ys i 1 prim + j merge-help
          }
        ] [
          res ys j prim seq-int.at prim seq-int.push
          locals { res } {
            res xs ys i j 1 prim + merge-help
          }
        ] if
      ] if
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } {
    xs ys prim seq-int.empty 0 0 merge-help
  };
```

### task: digits
```firth
: dig-help
  (forall ρ; ρ res:Seq Int^many n:Int^many -- ρ digits:Seq Int^many)
  locals { res n } {
    n 0 prim =
    [ res ] [
      res n 10 prim mod prim seq-int.push
      locals { res } {
        res n 10 prim div dig-help
      }
    ] if
  };

: fwd-build
  (forall ρ; ρ xs:Seq Int^many res:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { xs res i } {
    i xs prim seq-int.len prim >=
    [ res ] [
      res xs i prim seq-int.at prim seq-int.push
      locals { res } {
        xs res i 1 prim + fwd-build
      }
    ] if
  };

: rev-help
  (forall ρ; ρ xs:Seq Int^many res:Seq Int^many i:Int^many -- ρ reversed:Seq Int^many)
  locals { xs res i } {
    i 0 prim <
    [ res ] [
      res xs i prim seq-int.at prim seq-int.push
      locals { res } {
        res xs i 1 prim - rev-help
      }
    ] if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  dup 0 prim =
  [ drop prim seq-int.empty 0 prim seq-int.push ] [
    prim seq-int.empty swap dig-help
    locals { digits } {
      digits prim seq-int.empty 0 fwd-build
      locals { forward } {
        forward prim seq-int.empty forward prim seq-int.len 1 prim - rev-help
      }
    }
  ] if;
```
