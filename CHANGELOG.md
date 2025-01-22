# Changelog

## [0.15.2] - 2025-01-22

### Changed
- Enhanced validation for PayByToken payment data
- Improved handling of ccv_prime in InstallmentByToken
- Added currency as required parameter for PayByToken
- Improved test coverage for payment validation

## [0.15.1] - 2025-01-22

### Changed
- Enhanced Apple Pay and Line Pay implementations
- Improved code organization and readability

## [0.15.0] - 2025-01-22

### Changed
- Refactored refund functionality to be payment method agnostic
- Moved refund endpoint from CreditCard module to top level
- Simplified refund implementation for better maintainability

## [0.14.1] - 2025-01-21

### Added
- Added RSpec test coverage for Google Pay implementation

## [0.14.0] - 2025-01-17

### Added
- Added Apple Pay support with dedicated merchant ID handling
- Added support for Apple Pay payment processing
- Added comprehensive test coverage for Apple Pay implementation

## [0.13.0] - 2025-01-13

### Changed
- Made cardholder a required field for Line Pay and JKO Pay implementations
- Enhanced validation to ensure cardholder information (name, email, phone_number) is provided for these payment methods

## [0.12.1] - 2025-01-12

### Changed
- Improved test coverage to achieve 100% branch coverage
- Added test cases for result_url validation with nil values
- Enhanced test coverage for merchant ID handling in instalment payments

## [0.12.0] - 2025-01-08

### Changed
- Removed unnecessary `remember` parameter from LinePay and JkoPay implementations
- Moved `payment_data` method to protected scope in payment classes for better encapsulation
- Simplified LinePay implementation by removing redundant `by_prime` method
- Improved code organization and reduced duplication in payment classes

## [0.11.0] - 2025-01-02

### Changed
- Updated instalment periods to support correct values: 0 (no instalment), 3, 6, 12, 18, 24, 30 months
- Fixed instalment validation in tests to match actual supported periods
- Removed support for 36 months instalment period

## [0.10.0] - 2025-01-02

### Added
- Added support for `merchant_group_id` in payment processing
- Added ability to use either `merchant_id` or `merchant_group_id` for merchant identification
- Added support for 18 months instalment period

### Changed
- Modified payment validation to accept either `merchant_id` or `merchant_group_id`
- Updated configuration validation to support flexible merchant identification
- Improved payment data handling to prioritize `merchant_group_id` over all other merchant IDs
- When `merchant_group_id` is set, it now takes precedence over `line_pay_merchant_id`, `jko_pay_merchant_id`, and `instalment_merchant_id`
- Updated instalment validation to support periods: 0 (no instalment), 3, 6, 12, 18, 24, 30 months
- Enhanced error messages to clearly list all valid instalment options
- Improved instalment validation to only allow specific values: 0 (no instalment), 3, 6, 12, 18, 24, 30 months
- Enhanced error messages to clearly list all valid instalment options
- Updated tests to cover all valid and invalid instalment scenarios

## [0.9.0] - 2025-01-02

### Added
- Added test coverage for all configuration options
- Added test coverage for all error cases
- Achieved 100% test coverage (both line and branch coverage)

### Changed
- Improved test organization and descriptions
- Enhanced error handling test cases

## [0.8.0] - 2025-01-02

### Added
- Added JKO Pay support
  - New `JkoPay::Pay` class for processing JKO Pay payments
  - Added `jko_pay_merchant_id` configuration option
  - Added comprehensive test coverage for JKO Pay functionality

### Changed
- Set default instalment value to 0 (no instalment)
- Improved instalment validation to only allow specific values: 0 (no instalment), 3, 6, 12, 24, 30 months
- Enhanced error messages to clearly list all valid instalment options
- Updated tests to cover all valid and invalid instalment scenarios

### Fixed
- Fixed instalment validation to match TapPay's requirements
- Fixed test cases to reflect the new instalment validation rules

## [0.7.2] - 2025-01-02

### Added
- Added support for payment-specific merchant IDs:
  - `line_pay_merchant_id` for Line Pay transactions
  - `instalment_merchant_id` for instalment payments
- Added merchant ID fallback mechanism:
  1. Payment-specific merchant ID (if available)
  2. Default merchant ID

### Changed
- Updated instalment validation to allow 3-30 months instead of 1-12
- Improved validation error messages for result_url

## [0.7.1] - 2025-01-02

### Changed
- Removed unused redirect_url endpoint from Payment module
- Improved code organization by removing redundant endpoints

## [0.7.0] - 2025-01-02

### Added
- Added Line Pay support with dedicated payment flow
- Added Line Pay redirect URL handling

### Changed
- Refactored payment endpoints structure:
  - Moved common payment endpoints to a new `Payment` module
  - Separated payment-specific endpoints into their respective modules
  - Improved code organization and reusability
- Updated all payment classes to use the new endpoint structure

## [0.6.0] - 2024-12-31

### Added
- Added validation for `result_url` in credit card payments
- Required `result_url` with both `frontend_redirect_url` and `backend_notify_url` for 3D Secure transactions
- Required `result_url` with both `frontend_redirect_url` and `backend_notify_url` for instalment payments

### Changed
- Improved test coverage to 100% for both line and branch coverage
- Enhanced error messages for URL validation

## [0.5.1] - 2024-12-30

### Changed
- Removed `payment_url` from request parameters as it should only be handled in API response
- Updated documentation to clarify `payment_url` usage in 3D Secure, LINE Pay, and JKO Pay scenarios

## [0.5.0] - 2024-12-30

### Added
- Added support for `merchant_group_id` in payment requests (mutually exclusive with `merchant_id`)
- Updated API version to v3

### Changed
- Made `merchant_group_id` and `merchant_id` mutually exclusive, will raise error if both are provided
- Requires either `merchant_id` or `merchant_group_id` to be set

## [0.4.2] - 2024-12-30

### Changed
- Changed `redirect_url` to `payment_url` in payment data
- Made `payment_url` optional in payment requests

## [0.4.1] - 2024-12-30

### Changed
- Enhanced transaction query response to include additional fields:
  - records_per_page
  - page
  - total_page_count
  - number_of_transactions

## [0.4.0] - 2024-12-25

### Changed
- Refactored payment and instalment classes to share common base class
- Unified payment endpoints for both regular and instalment payments
- Removed redundant endpoint URLs in favor of unified payment endpoints
- Made instalment parameter required for instalment payments (removed default value)

### Breaking Changes
- Renamed endpoint methods to `payment_by_prime_url` and `payment_by_token_url`
- Instalment payments now require explicit instalment parameter
- Removed default instalment value of 1

## [0.3.0] - 2024-12-24

### Added
- Separated instalment endpoints for prime and token payments
- Added `instalment_by_prime_url` and `instalment_by_token_url` endpoints
- Updated instalment classes to use their respective endpoints

## [0.2.32] - 2024-12-24

### Fixed
- Fixed cardholder parameter validation in InstalmentByPrime

## [0.2.31] - 2024-12-24

### Fixed
- Fixed cardholder parameter being added to payment data in InstalmentByPrime

## [0.2.30] - 2024-12-24

### Fixed
- Fixed cardholder parameter being added to payment data in base class

## [0.2.29] - 2024-12-24

### Fixed
- Fixed cardholder validation for instalment payments

## [0.2.28] - 2024-12-24

### Fixed
- Fixed NoMethodError when cardholder is nil

## [0.2.27] - 2024-12-24

### Fixed
- Fixed cardholder parameter being always included in payment data even when not provided

## [0.2.26] - 2024-12-24

### Fixed
- Removed cardholder parameter from InstallmentByToken to match TapPay API requirements

## [0.2.25] - 2024-12-24

### Fixed
- Added cardholder parameter requirement for InstallmentByToken to match TapPay API requirements

## [0.2.22] - 2024-12-24

### Fixed
- Removed cardholder requirement from InstallmentByToken to match TapPay API requirements

## [0.2.20] - 2024-12-23

### Fixed
- Fixed parameter name for cardholder in InstallmentBase class to match TapPay API requirements

## [0.2.19] - 2024-12-23

### Fixed
- Fixed parameter name for cardholder in regular payments to match TapPay API requirements

## [0.2.18] - 2024-12-23

### Fixed
- Fixed parameter name for cardholder in instalment payments to match TapPay API requirements

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

## [Unreleased]