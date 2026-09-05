from pathlib import Path
import unittest

ROOT = Path(__file__).parents[1]


class WeatherTest(unittest.TestCase):
    def test_weather_uses_configured_city_and_celsius(self) -> None:
        state = (ROOT / "modules/weather/WeatherState.qml").read_text()
        config = (ROOT / "core/ConfigStore.qml").read_text()

        self.assertIn("configStore.weatherLocation", state)
        self.assertIn('current.temp_C', state)
        self.assertIn('+ "°C"', state)
        self.assertIn("function setWeatherLocation", config)

    def test_weather_location_is_read_only_until_change_is_requested(self) -> None:
        panel = (ROOT / "modules/weather/WeatherPanel.qml").read_text()

        self.assertIn("property bool editingLocation: false", panel)
        self.assertIn('text: "Change"', panel)
        self.assertIn("onClicked: root.beginLocationEdit()", panel)
        self.assertRegex(panel, r"TextField\s*\{[^}]*visible:\s*root\.editingLocation")

    def test_weather_exposes_hourly_and_five_day_forecasts(self) -> None:
        state = (ROOT / "modules/weather/WeatherState.qml").read_text()
        panel = (ROOT / "modules/weather/WeatherPanel.qml").read_text()

        self.assertIn("property var hourlyForecast: []", state)
        self.assertIn("property var dailyForecast: []", state)
        self.assertIn("forecast_days=6", state)
        self.assertIn("hours.length < 7", state)
        self.assertIn("days.length < 5", state)
        self.assertIn("model: root.weatherState.hourlyForecast", panel)
        self.assertIn("model: root.weatherState.dailyForecast", panel)
        self.assertIn("root.weatherState.feelsLikeCelsius", panel)
        self.assertIn("root.weatherState.humidityPercent", panel)

    def test_weather_panel_uses_condition_driven_rain_glass(self) -> None:
        panel = (ROOT / "modules/weather/WeatherPanel.qml").read_text()
        scene = (ROOT / "modules/weather/WeatherScene.qml").read_text()
        glass = (ROOT / "modules/weather/GlassPane.qml").read_text()
        shader = (ROOT / "modules/weather/shaders/rainglass.frag").read_text()

        self.assertIn("WeatherScene", panel)
        self.assertIn("TextField", panel)
        self.assertIn('weatherKind === "rain"', scene)
        self.assertIn('weatherKind === "snow"', scene)
        self.assertIn('weatherKind === "storm"', scene)
        self.assertIn("GlassPane", scene)
        self.assertIn("ShaderEffectSource", glass)
        self.assertIn("MultiEffect", glass)
        self.assertIn("rainAmount", shader)
        self.assertIn("snowAmount", shader)
        self.assertTrue((ROOT / "modules/weather/shaders/rainglass.frag.qsb").is_file())


if __name__ == "__main__":
    unittest.main()
