# Changelog

## [0.2.6] - 2024-12-19

### Fixed
- Fixed gem loading issue by using proper require_relative

## [0.2.5] - 2024-12-19

### Added
- Added support for requiring gem as 'tappay'

## [0.2.4] - 2024-12-19

### Added
- Added support for requiring gem as 'tappay_ruby'

## [0.2.3] - 2024-12-19

### Changed
- Updated GitHub Actions workflow for gem publishing

## [0.2.1] - 2024-12-19

### Changed
- Improved CardHolder handling in Pay class
- Added support for direct Hash input for cardholder information
- Updated README with comprehensive cardholder information examples
- Renamed `as_json` to `to_h` in CardHolder class (kept `as_json` as alias for backward compatibility)

## [0.2.0] - 2024-12-19

### Added
- Added `CardHolder` class for managing cardholder information
- Added environment-based endpoint management
- Added automatic sandbox/production URL switching
- Added comprehensive configuration options (direct, environment variables, Rails credentials)

### Changed
- Improved README with detailed configuration examples
- Updated code documentation
- Reorganized endpoint URLs into a dedicated module

### Fixed
- Fixed endpoint URL handling in sandbox mode
- Improved error handling in configuration

## [0.1.0] - 2024-12-18

### Added
- Initial release
- Basic TapPay integration
- Credit card payment support
- Refund processing
- Transaction queries
- Basic error handling