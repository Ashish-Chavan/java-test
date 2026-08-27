package com.experian.ais.vhr.security.config;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Unit tests verifying that {@link User} field defaults for the report section indicators
 * are {@code true} across all construction paths.
 *
 * <p>Validates: Requirements 5.1
 */
class UserDefaultsTest {

    @Test
    @DisplayName("No-arg constructor defaults windowStickerIn to true")
    void noArgConstructor_windowStickerIn_defaultsTrue() {
        User user = new User();
        assertTrue(user.isWindowStickerIn());
    }

    @Test
    @DisplayName("No-arg constructor defaults warrantySectionIn to true")
    void noArgConstructor_warrantySectionIn_defaultsTrue() {
        User user = new User();
        assertTrue(user.isWarrantySectionIn());
    }

    @Test
    @DisplayName("2-arg constructor defaults windowStickerIn to true")
    void twoArgConstructor_windowStickerIn_defaultsTrue() {
        User user = new User("testCid", "testPassword");
        assertTrue(user.isWindowStickerIn());
    }

    @Test
    @DisplayName("2-arg constructor defaults warrantySectionIn to true")
    void twoArgConstructor_warrantySectionIn_defaultsTrue() {
        User user = new User("testCid", "testPassword");
        assertTrue(user.isWarrantySectionIn());
    }

    @Test
    @DisplayName("3-arg constructor defaults windowStickerIn to true")
    void threeArgConstructor_windowStickerIn_defaultsTrue() {
        User user = new User("testCid", "testPassword", "testSid");
        assertTrue(user.isWindowStickerIn());
    }

    @Test
    @DisplayName("3-arg constructor defaults warrantySectionIn to true")
    void threeArgConstructor_warrantySectionIn_defaultsTrue() {
        User user = new User("testCid", "testPassword", "testSid");
        assertTrue(user.isWarrantySectionIn());
    }

    @Test
    @DisplayName("15-arg constructor defaults windowStickerIn to true")
    void fifteenArgConstructor_windowStickerIn_defaultsTrue() {
        User user = new User("cid", "pass", "sid", "org", true, true,
                "addr", "city", "state", "zip", "phone", "url", "elite", "type", false);
        assertTrue(user.isWindowStickerIn());
    }

    @Test
    @DisplayName("15-arg constructor defaults warrantySectionIn to true")
    void fifteenArgConstructor_warrantySectionIn_defaultsTrue() {
        User user = new User("cid", "pass", "sid", "org", true, true,
                "addr", "city", "state", "zip", "phone", "url", "elite", "type", false);
        assertTrue(user.isWarrantySectionIn());
    }
}
