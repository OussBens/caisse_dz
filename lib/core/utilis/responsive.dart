class Responsive {
  static double sidebarWidth(double screenWidth) {
    return (screenWidth * 0.13).clamp(250, 350);
  }
  static double sidebarHeight(double screenHeight) {
    return (screenHeight * 1).clamp(800, 1300);
  }
  static double notificationSize(double screenHeight) {
    return (screenHeight * 0.04).clamp(22, 50);
  }
  static double TableauWidth(double screenWidth) {
    return (screenWidth * 0.85).clamp(800, 2000);
  }
  static double TableauHeight(double screenHeight) {
    return (screenHeight * 0.6).clamp(500, 1000);
  }

}