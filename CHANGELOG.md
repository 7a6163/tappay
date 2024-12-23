# Changelog

## [0.2.17] - 2024-12-23

### Changed
- Refactored instalment payment classes to have their own base class
- Removed dependency on PayBase class for instalment payments
- Simplified class hierarchy for better maintainability

## [0.2.16] - 2024-12-23

### Changed
- Removed unnecessary execute method from Instalment class
- Simplified class hierarchy for instalment payments

## [0.2.15] - 2024-12-23

### Fixed
- Fixed inheritance structure of Instalment classes
- Added proper error message when trying to use Instalment class directly
- Updated InstalmentService to correctly use by_prime and by_token methods

## [0.2.13] - 2024-12-23

### Added
- Added by_prime and by_token class methods to Instalment class
- Added execute method to Instalment class for handling instalment payments

### Fixed
- Fixed instalment payment handling in client applications

## [0.2.12] - 2024-12-23

### Fixed
- Simplified PayByPrime and PayByToken execute methods to return raw response
- Updated response handling in client applications

## [0.2.11] - 2024-12-23

### Changed
- Refactored HTTP response handling in Client class
- Modified Client#post to return raw response object
- Added response parsing in PayByPrime and PayByToken execute methods
- Improved error handling with better separation of concerns

## [0.2.10] - 2024-12-23

### Changed
- Modified Pay.by_prime and Pay.by_token to return payment objects instead of executing them immediately
- This change allows more flexibility in payment flow control and better error handling

## [0.2.9] - 2024-12-23

### Fixed
- Removed partner_key and merchant_id from required options validation as they should be taken from configuration

## [0.2.8] - 2024-12-23

### Changed
- Updated required fields validation for PayByPrime and PayByToken
- Added details as required field for both PayByPrime and PayByToken
- Made currency a required field for PayByToken and removed its default value
- Removed order_number from required fields

## [0.2.7] - 2024-12-19

### Added
- Added app_id configuration option

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