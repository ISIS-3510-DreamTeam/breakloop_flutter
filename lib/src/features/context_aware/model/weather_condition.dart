enum WeatherCondition {
  clear,
  cloudy,
  rain,
  snow;

  //Maps the WMO weather code returned by Open-Meteo to our conditions. Unknown codes count as cloudy
  static WeatherCondition fromWmoCode(int code) {
    if (code == 0 || code == 1) {
      return WeatherCondition.clear;
    } else if (code == 2 || code == 3 || code == 45 || code == 48) {
      return WeatherCondition.cloudy;
    } else if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82) || (code >= 95 && code <= 99)) {
      return WeatherCondition.rain;
    } else if ((code >= 71 && code <= 77) || code == 85 || code == 86) {
      return WeatherCondition.snow;
    }
    return WeatherCondition.cloudy;
  }
}
