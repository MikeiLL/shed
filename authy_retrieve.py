# Retrieve shared secrets from Authy

# Once you have the shared secrets in hand, you can generate TOTP codes
# using pyotp fairly easily:
#     pyotp.TOTP("JBSWY3DPEHPK3PXP", 8).now()
# Digit length, if omitted, is six.

# This app works by creating a new device for an existing user, and then
# asking Authy servers to synchronize with it. Will require the user's
# master password or perhaps backup password.
