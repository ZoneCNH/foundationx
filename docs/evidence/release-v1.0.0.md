# kernel v1.0.0 Release Evidence

- **Version**: v1.0.0
- **Date**: 2026-06-12
- **Go Version**: 1.23
- **Module**: github.com/ZoneCNH/kernel

## Gates

| Gate | Status |
|------|:------:|
| fmt | ✅ |
| vet | ✅ |
| lint | ✅ |
| test | ✅ |
| coverage (100%) | ✅ |
| race | ✅ |
| bench-check | ✅ |
| boundary | ✅ |
| security | ✅ |
| contracts | ✅ |
| api-check | ✅ |
| docs | ✅ |
| artifact | ✅ |
| dependency | ✅ |
| standard-drift | ✅ |
| workflow-pin | ✅ |
| examples (12) | ✅ |
| stdlib-only | ✅ |
| secret-scan | ✅ |

## Performance

| Benchmark | Result | Target |
|-----------|--------|--------|
| NewError | ~0.4 ns | < 100ns |
| IsKind (5-layer) | ~35 ns | < 1μs |
| Delay | ~3 ns | < 100ns |
| Aggregate (10) | ~530 ns | < 10μs |

## Coverage

- Core library (12 subpackages): 100%
- All tests passing with -race
