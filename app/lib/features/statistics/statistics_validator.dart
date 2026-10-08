class StatisticsValidator {
  static bool sonDatosValidos({
    required int estudiantesActivos,
    required double ingresosSuscripciones,
    required double ingresosVentas,
  }) {
    return estudiantesActivos >= 0 &&
        ingresosSuscripciones >= 0 &&
        ingresosVentas >= 0;
  }
}
