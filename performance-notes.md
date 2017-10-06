
### 2017-10-05
OSX with Custom written Double-double float parser

Compiling ...
  0.086553 seconds (42.38 k allocations: 2.636 MiB)
  0.163412 seconds (125.63 k allocations: 6.056 MiB)
  2.804167 seconds (2.30 M allocations: 115.915 MiB, 4.67% gc time)
  0.066359 seconds (88.03 k allocations: 2.778 MiB)
Performance ...
  2.900880 seconds (42 allocations: 257.004 MiB, 2.34% gc time)
  3.358630 seconds (36 allocations: 257.004 MiB, 1.53% gc time)
  5.045401 seconds (67.11 M allocations: 1.781 GiB, 5.23% gc time)
 12.642750 seconds (67.11 M allocations: 1.781 GiB, 1.19% gc time)
Faster parsing
  2.845484 seconds (48 allocations: 257.004 MiB, 2.73% gc time)
  3.199806 seconds (82 allocations: 257.006 MiB, 2.22% gc time)

### 2017-09-29
OSX with Native Julia float parsing (directly called, no string functions)

Compiling ...
  0.096325 seconds (42.32 k allocations: 2.628 MiB)
  0.189094 seconds (141.37 k allocations: 7.786 MiB, 32.27% gc time)
  2.864678 seconds (2.27 M allocations: 114.153 MiB, 2.86% gc time)
  0.070057 seconds (88.03 k allocations: 2.777 MiB)
Performance ...
  2.683775 seconds (42 allocations: 257.004 MiB, 2.54% gc time)
  9.465988 seconds (36 allocations: 257.004 MiB, 0.53% gc time)
  5.148951 seconds (67.11 M allocations: 1.781 GiB, 4.75% gc time)
 12.920094 seconds (67.11 M allocations: 1.781 GiB, 1.15% gc time)
Faster parsing
  2.684360 seconds (48 allocations: 257.004 MiB, 3.06% gc time)
  9.312499 seconds (82 allocations: 257.006 MiB, 0.63% gc time)
