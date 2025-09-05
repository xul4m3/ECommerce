Feature: ECommerce Platform End-to-End Testing
  As an online shopper and platform administrator
  I want to be able to use all core ecommerce functionality
  So that I can successfully buy products and manage the platform

  Background:
    Given the ECommerce platform is available and running
    And the product catalog is populated with test data
    And payment gateways are configured for testing

  @smoke @user-registration
  Scenario: User Registration and Profile Setup
    Given I am on the registration page
    When I enter valid registration details:
      | field     | value                    |
      | email     | testuser@example.com     |
      | password  | SecurePass123!           |
      | firstName | John                     |
      | lastName  | Doe                      |
    And I submit the registration form
    Then I should see a registration success message
    And I should receive an email verification link
    When I click the verification link
    Then my account should be activated
    And I should be able to log in with my credentials

  @smoke @authentication
  Scenario: User Login and Logout
    Given I have a registered user account with email "testuser@example.com"
    When I navigate to the login page
    And I enter my credentials:
      | email    | testuser@example.com |
      | password | SecurePass123!       |
    And I click the login button
    Then I should be redirected to my dashboard
    And I should see my profile information
    When I click the logout button
    Then I should be logged out
    And I should be redirected to the homepage

  @product-catalog
  Scenario: Browse Product Catalog
    Given I am on the homepage
    When I browse the product categories
    Then I should see products organized by category
    When I click on "Electronics" category
    Then I should see all electronics products
    And I should see filtering options for:
      | filter    |
      | Price     |
      | Brand     |
      | Rating    |
      | Features  |
    When I apply a price filter "Under $500"
    Then I should only see products priced under $500

  @product-search
  Scenario: Product Search Functionality
    Given I am on the homepage
    When I enter "smartphone" in the search box
    And I click the search button
    Then I should see search results for smartphones
    And the results should be sorted by relevance
    When I sort by "Price: Low to High"
    Then the results should be reordered by ascending price
    When I filter by "4+ star rating"
    Then I should only see highly rated smartphones

  @product-details
  Scenario: View Product Details
    Given I am browsing the product catalog
    When I click on a product "iPhone 15 Pro"
    Then I should see the product details page with:
      | element           |
      | Product name      |
      | Product images    |
      | Price             |
      | Description       |
      | Specifications    |
      | Customer reviews  |
      | Stock status      |
      | Add to cart button|
    And I should see product variants for color and storage
    When I select a different color variant
    Then the product images should update to show the selected color
    And the price should update if applicable

  @shopping-cart
  Scenario: Add Products to Shopping Cart
    Given I am viewing a product "Wireless Headphones"
    And the product is in stock
    When I select quantity "2"
    And I click "Add to Cart"
    Then I should see a cart confirmation message
    And the cart icon should show "2" items
    When I click on the cart icon
    Then I should see the cart with:
      | product           | quantity | price  |
      | Wireless Headphones| 2       | $199.98|
    And I should see the subtotal as "$199.98"

  @shopping-cart
  Scenario: Update Shopping Cart
    Given I have items in my shopping cart:
      | product          | quantity | price   |
      | Laptop          | 1        | $999.99 |
      | Mouse           | 2        | $49.98  |
    When I go to my shopping cart
    And I update the laptop quantity to "2"
    Then the cart should show:
      | product          | quantity | price    |
      | Laptop          | 2        | $1999.98 |
      | Mouse           | 2        | $49.98   |
    And the total should be "$2049.96"
    When I remove the mouse from cart
    Then the cart should only contain the laptop
    And the total should be "$1999.98"

  @guest-checkout
  Scenario: Guest Checkout Process
    Given I have items in my cart as a guest user
    When I proceed to checkout
    Then I should see options to:
      | option                    |
      | Checkout as guest         |
      | Create account            |
      | Sign in to existing account|
    When I choose "Checkout as guest"
    And I enter shipping information:
      | field      | value              |
      | firstName  | Jane               |
      | lastName   | Smith              |
      | email      | jane@example.com   |
      | address    | 123 Main St        |
      | city       | New York           |
      | zipCode    | 10001              |
      | phone      | +1-555-0123        |
    And I select shipping method "Standard (5-7 days)"
    And I enter payment information:
      | field       | value              |
      | cardNumber  | 4242424242424242   |
      | expiryDate  | 12/25              |
      | cvv         | 123                |
    And I click "Place Order"
    Then I should see an order confirmation page
    And I should receive an order confirmation email

  @registered-checkout
  Scenario: Registered User Checkout with Saved Information
    Given I am logged in as a registered user
    And I have saved addresses and payment methods
    And I have items in my cart
    When I proceed to checkout
    Then I should see my saved shipping addresses
    And I should see my saved payment methods
    When I select my preferred shipping address
    And I select my preferred payment method
    And I choose "Express (2-3 days)" shipping
    And I apply coupon code "SAVE10"
    Then I should see a 10% discount applied
    When I click "Place Order"
    Then I should see an order confirmation
    And the order should appear in my order history

  @order-management
  Scenario: Order Tracking and History
    Given I am a logged-in user with previous orders
    When I go to my account dashboard
    And I click on "Order History"
    Then I should see a list of my previous orders
    When I click on an order "ORD-123456"
    Then I should see order details including:
      | detail          |
      | Order number    |
      | Order date      |
      | Items ordered   |
      | Shipping address|
      | Payment method  |
      | Order status    |
      | Tracking number |
    When the order status is "Shipped"
    Then I should be able to track the shipment
    And I should see estimated delivery date

  @user-profile
  Scenario: User Profile Management
    Given I am logged in as a registered user
    When I go to my profile settings
    Then I should be able to update:
      | field            |
      | Personal information|
      | Email address    |
      | Password         |
      | Shipping addresses|
      | Payment methods  |
      | Communication preferences|
    When I add a new shipping address:
      | field      | value              |
      | label      | Work Address       |
      | address    | 456 Business Ave   |
      | city       | Chicago            |
      | zipCode    | 60601              |
    And I save the changes
    Then the new address should appear in my address book
    And I should be able to select it during checkout

  @wishlist
  Scenario: Product Wishlist Management
    Given I am logged in as a registered user
    When I view a product "Smart Watch"
    And I click the "Add to Wishlist" button
    Then the product should be added to my wishlist
    When I go to my wishlist
    Then I should see the "Smart Watch" in my wishlist
    And I should be able to:
      | action                    |
      | View product details      |
      | Add to cart from wishlist |
      | Remove from wishlist      |
      | Share wishlist            |
    When I click "Add to Cart" for the smart watch
    Then the item should be added to my cart
    But it should remain in my wishlist

  @product-reviews
  Scenario: Product Reviews and Ratings
    Given I am a logged-in user who has purchased a product
    When I go to my order history
    And I select a delivered order containing "Bluetooth Speaker"
    Then I should see an option to "Write a Review"
    When I click "Write a Review"
    And I provide a rating of 5 stars
    And I write a review "Excellent sound quality and battery life"
    And I submit the review
    Then I should see a confirmation that my review was submitted
    When I visit the product page for "Bluetooth Speaker"
    Then I should see my review displayed
    And the product rating should reflect my 5-star rating

  @promotions
  Scenario: Discount Codes and Promotions
    Given there is an active promotion "NEWUSER20" offering 20% off
    And I have items worth $100 in my cart
    When I proceed to checkout
    And I enter the coupon code "NEWUSER20"
    And I click "Apply Coupon"
    Then I should see a discount of $20 applied
    And my total should be $80 (plus taxes and shipping)
    When I enter an invalid coupon code "INVALID"
    Then I should see an error message "Invalid coupon code"
    And no discount should be applied

  @admin-product-management
  Scenario: Admin Product Management
    Given I am logged in as an admin user
    When I go to the admin dashboard
    And I navigate to "Product Management"
    Then I should see a list of all products
    When I click "Add New Product"
    And I fill in product details:
      | field        | value                    |
      | name         | New Gaming Mouse         |
      | category     | Electronics > Computers |
      | price        | 79.99                   |
      | description  | High-precision gaming mouse|
      | stock        | 50                      |
    And I upload product images
    And I click "Save Product"
    Then the product should be created successfully
    And it should appear in the product catalog
    When I search for "New Gaming Mouse" on the frontend
    Then I should find the newly created product

  @admin-order-management
  Scenario: Admin Order Management
    Given I am logged in as an admin user
    And there are pending orders in the system
    When I go to the admin dashboard
    And I navigate to "Order Management"
    Then I should see a list of all orders with their statuses
    When I filter orders by status "Pending"
    Then I should see only pending orders
    When I click on order "ORD-789123"
    Then I should see detailed order information
    When I update the order status to "Processing"
    And I add a tracking number "TRK-456789"
    And I click "Update Order"
    Then the order status should be updated
    And the customer should receive a notification email

  @inventory-management
  Scenario: Inventory Alerts and Management
    Given I am logged in as an admin user
    And there are products with low inventory
    When I go to the admin dashboard
    Then I should see low inventory alerts
    When I navigate to "Inventory Management"
    And I filter by "Low Stock" items
    Then I should see products with stock below threshold
    When I select a product "Wireless Earbuds" with 2 items remaining
    And I update the stock to 100
    And I save the changes
    Then the product should no longer appear in low stock alerts
    And the product should be available for purchase on the frontend

  @payment-processing
  Scenario: Payment Failure Handling
    Given I have items in my cart
    When I proceed to checkout as a guest
    And I enter shipping information
    And I enter invalid payment information:
      | field       | value            |
      | cardNumber  | 4000000000000002 |
      | expiryDate  | 12/25            |
      | cvv         | 123              |
    And I click "Place Order"
    Then I should see a payment failure message
    And I should be able to retry with different payment information
    When I enter valid payment information:
      | field       | value              |
      | cardNumber  | 4242424242424242   |
      | expiryDate  | 12/25              |
      | cvv         | 123                |
    And I click "Place Order"
    Then the order should be processed successfully

  @mobile-responsive
  Scenario: Mobile Shopping Experience
    Given I am using a mobile device
    When I visit the homepage
    Then the layout should be mobile-responsive
    And I should see a mobile-friendly navigation menu
    When I search for "tablet" using the mobile search
    Then I should see search results optimized for mobile
    When I view a product on mobile
    Then the product images should be touch-friendly
    And I should be able to add the product to cart easily
    When I proceed to checkout on mobile
    Then the checkout form should be mobile-optimized
    And I should be able to complete the purchase

  @performance
  Scenario: Page Load Performance
    Given I am on the homepage
    When I measure the page load time
    Then the page should load within 3 seconds
    When I perform a product search
    Then the search results should appear within 1 second
    When I navigate between product pages
    Then each page should load within 2 seconds
    And images should load progressively

  @security
  Scenario: Security and Data Protection
    Given I am registering a new account
    When I enter a weak password "123"
    Then I should see password strength requirements
    And I should not be able to submit the form
    When I enter a strong password "StrongPass123!"
    Then the password should be accepted
    When I log in successfully
    Then my session should be secure
    And sensitive data should not be exposed in browser storage
    When I log out
    Then my session should be completely terminated

  @accessibility
  Scenario: Accessibility Compliance
    Given I am using a screen reader
    When I navigate the homepage
    Then all images should have alt text
    And all form fields should have proper labels
    When I use keyboard navigation only
    Then I should be able to navigate through all interactive elements
    And focus indicators should be clearly visible
    When I view product information
    Then color should not be the only way to convey information
    And text contrast should meet WCAG standards

  @multilingual
  Scenario: Multi-language Support
    Given the platform supports multiple languages
    When I select "Spanish" from the language selector
    Then the interface should display in Spanish
    And product information should be in Spanish where available
    When I switch back to "English"
    Then the interface should return to English
    And my language preference should be remembered

  @error-handling
  Scenario: Graceful Error Handling
    Given the system encounters an unexpected error
    When I try to access a non-existent product page
    Then I should see a user-friendly 404 error page
    And I should see suggestions for alternative products
    When the payment service is temporarily unavailable
    Then I should see an appropriate error message
    And I should be offered alternative payment methods
    When there is a server error during checkout
    Then my cart should be preserved
    And I should be able to retry the checkout process