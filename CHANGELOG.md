## 2.1.0

- Fix #13: Tags are not preserved when Gauge and Counter types are encoded (thanks lmmfranco)
- Fix #14: Futures are double completed when PDUs contain an error (thanks lmmfranco)
- Fix #15: Request queue leak when requests error (thanks lmmfranco)
- Fix #9: Bump asn1lib to 1.2.2 to prevent tag encoding issue
- Use lints package for linting (instead of deprecated pedantic)
- Add dart_code_metrics for even stricter linting

## 2.0.0

- Close method now logs instead of throws (#2)

## 2.0.0-dev

- Nullsafety

## 1.0.2-dev

- Add documentation, upgrade dependencies

## 1.0.1-dev

- Improve description, pass static analysis, add example main.dart

## 1.0.0-dev

- Initial version, with SNMP v1 / v2c basic commands support
