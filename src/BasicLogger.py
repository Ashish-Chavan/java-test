import logging

logging.basicConfig(level=logging.DEBUG)

def register_user(username: str, email: str):
    logging.debug(f"Starting registration for user: {username}")
    if not email.endswith("@example.com"):
        logging.warning(f"Non-company email detected: {email}")

    if "@" not in email:
        logging.error(f"Invalid email format: {email}")
        return False

    logging.info(f"User {username} registered successfully with email {email}")
    return True

register_user("john_doe", "john@example.com")
register_user("fake_user", "invalid_email")
