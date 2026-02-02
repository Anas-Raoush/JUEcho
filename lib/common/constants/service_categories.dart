/// service_categories.dart
///
/// Service categories enum and mapping helpers.
///
/// Purpose
/// - Defines service categories used in submissions, filters, and analytics.
/// - Centralizes UI labels and backend keys.
/// - Enforces strong typing across the codebase instead of raw strings.
///
/// Mapping strategy
/// - [ServiceCategoryLabel] provides user-facing labels.
/// - [ServiceCategoryKey] provides backend-safe GraphQL enum keys.
/// - [ServiceCategoryParser] converts backend keys back into the enum.
enum ServiceCategories {
  /// Transportation services provided to students.
  studentTransportationServices,

  /// On-campus or university-managed food providers.
  foodServices,

  /// Health services dedicated to students (student clinic).
  studentClinic,

  /// Library-related services (borrowing, catalog, reading rooms, etc.).
  libraryServices,

  /// Sports and physical activities complex.
  sportsActivitiesComplex,

  /// Dormitories for international students or non-local residents.
  internationalDormitories,

  /// Language center offerings.
  languageCenter,

  /// E-learning platform.
  eLearningPlatform,

  /// Registration and admissions services.
  registrationAndAdmissionsServices,

  /// Jordan University Hospital related services.
  jordanUniversityHospital,

  /// Financial aid and scholarships office/services.
  financialAidAndScholarships,

  /// IT support services.
  itSupportServices,

  /// Career guidance and counseling services.
  careerGuidanceAndCounseling,

  /// Student affairs and extracurricular activities office/services.
  studentAffairsAndExtracurricularActivities,

  /// Security and campus safety services.
  securityAndCampusSafety,

  /// Maintenance and facilities management services.
  maintenanceAndFacilitiesManagement,

  /// Parking-related services and policies.
  parkingServices,

  /// Printing and photocopying services for students/staff.
  printingAndPhotocopyingServices,

  /// Bookstore services.
  bookstoreServices,

  /// Alumni relations office and services.
  alumniRelationsOffice,
}

/// UI-facing label mapping for [ServiceCategories].
///
/// Intended usage
/// - Dropdowns
/// - Chips
/// - Tables and cards
extension ServiceCategoryLabel on ServiceCategories {
  /// Human-readable label for display in UI surfaces.
  String get label {
    switch (this) {
      case ServiceCategories.studentTransportationServices:
        return 'Student Transportation Services';
      case ServiceCategories.foodServices:
        return 'Food Services';
      case ServiceCategories.studentClinic:
        return 'Student Clinic';
      case ServiceCategories.libraryServices:
        return 'Library Services';
      case ServiceCategories.sportsActivitiesComplex:
        return 'Sports Activities Complex';
      case ServiceCategories.internationalDormitories:
        return 'International Dormitories';
      case ServiceCategories.languageCenter:
        return 'Language Center';
      case ServiceCategories.eLearningPlatform:
        return 'E-learning Platform';
      case ServiceCategories.registrationAndAdmissionsServices:
        return 'Registration and Admissions Services';
      case ServiceCategories.jordanUniversityHospital:
        return 'Jordan University Hospital';
      case ServiceCategories.financialAidAndScholarships:
        return 'Financial Aid and Scholarships';
      case ServiceCategories.itSupportServices:
        return 'IT Support Services';
      case ServiceCategories.careerGuidanceAndCounseling:
        return 'Career Guidance and Counseling';
      case ServiceCategories.studentAffairsAndExtracurricularActivities:
        return 'Student Affairs & Extracurricular Activities';
      case ServiceCategories.securityAndCampusSafety:
        return 'Security & Campus Safety';
      case ServiceCategories.maintenanceAndFacilitiesManagement:
        return 'Maintenance & Facilities Management';
      case ServiceCategories.parkingServices:
        return 'Parking Services';
      case ServiceCategories.printingAndPhotocopyingServices:
        return 'Printing & Photocopying Services';
      case ServiceCategories.bookstoreServices:
        return 'Bookstore Services';
      case ServiceCategories.alumniRelationsOffice:
        return 'Alumni Relations Office';
    }
  }
}

/// Backend key mapping for [ServiceCategories].
///
/// Notes
/// - Keys must match GraphQL schema enum values exactly (UPPER_SNAKE_CASE).
extension ServiceCategoryKey on ServiceCategories {
  /// Backend-safe enum key used in GraphQL operations.
  String get key {
    switch (this) {
      case ServiceCategories.studentTransportationServices:
        return 'STUDENT_TRANSPORTATION_SERVICES';
      case ServiceCategories.foodServices:
        return 'FOOD_SERVICES';
      case ServiceCategories.studentClinic:
        return 'STUDENT_CLINIC';
      case ServiceCategories.libraryServices:
        return 'LIBRARY_SERVICES';
      case ServiceCategories.sportsActivitiesComplex:
        return 'SPORTS_ACTIVITIES_COMPLEX';
      case ServiceCategories.internationalDormitories:
        return 'INTERNATIONAL_DORMITORIES';
      case ServiceCategories.languageCenter:
        return 'LANGUAGE_CENTER';
      case ServiceCategories.eLearningPlatform:
        return 'E_LEARNING_PLATFORM';
      case ServiceCategories.registrationAndAdmissionsServices:
        return 'REGISTRATION_AND_ADMISSIONS_SERVICES';
      case ServiceCategories.jordanUniversityHospital:
        return 'JORDAN_UNIVERSITY_HOSPITAL';
      case ServiceCategories.financialAidAndScholarships:
        return 'FINANCIAL_AID_AND_SCHOLARSHIPS';
      case ServiceCategories.itSupportServices:
        return 'IT_SUPPORT_SERVICES';
      case ServiceCategories.careerGuidanceAndCounseling:
        return 'CAREER_GUIDANCE_AND_COUNSELING';
      case ServiceCategories.studentAffairsAndExtracurricularActivities:
        return 'STUDENT_AFFAIRS_AND_EXTRACURRICULAR_ACTIVITIES';
      case ServiceCategories.securityAndCampusSafety:
        return 'SECURITY_AND_CAMPUS_SAFETY';
      case ServiceCategories.maintenanceAndFacilitiesManagement:
        return 'MAINTENANCE_AND_FACILITIES_MANAGEMENT';
      case ServiceCategories.parkingServices:
        return 'PARKING_SERVICES';
      case ServiceCategories.printingAndPhotocopyingServices:
        return 'PRINTING_AND_PHOTOCOPYING_SERVICES';
      case ServiceCategories.bookstoreServices:
        return 'BOOKSTORE_SERVICES';
      case ServiceCategories.alumniRelationsOffice:
        return 'ALUMNI_RELATIONS_OFFICE';
    }
  }
}

/// Parser utilities for converting backend keys into [ServiceCategories].
///
/// Failure mode
/// - Throws [ArgumentError] on unknown keys to surface schema drift immediately.
extension ServiceCategoryParser on ServiceCategories {
  /// Converts a GraphQL enum key (UPPER_SNAKE_CASE) into a strongly typed value.
  ///
  /// Throws
  /// - [ArgumentError] when [key] does not match any known service category.
  static ServiceCategories fromKey(String key) {
    switch (key) {
      case 'STUDENT_TRANSPORTATION_SERVICES':
        return ServiceCategories.studentTransportationServices;
      case 'FOOD_SERVICES':
        return ServiceCategories.foodServices;
      case 'STUDENT_CLINIC':
        return ServiceCategories.studentClinic;
      case 'LIBRARY_SERVICES':
        return ServiceCategories.libraryServices;
      case 'SPORTS_ACTIVITIES_COMPLEX':
        return ServiceCategories.sportsActivitiesComplex;
      case 'INTERNATIONAL_DORMITORIES':
        return ServiceCategories.internationalDormitories;
      case 'LANGUAGE_CENTER':
        return ServiceCategories.languageCenter;
      case 'E_LEARNING_PLATFORM':
        return ServiceCategories.eLearningPlatform;
      case 'REGISTRATION_AND_ADMISSIONS_SERVICES':
        return ServiceCategories.registrationAndAdmissionsServices;
      case 'JORDAN_UNIVERSITY_HOSPITAL':
        return ServiceCategories.jordanUniversityHospital;
      case 'FINANCIAL_AID_AND_SCHOLARSHIPS':
        return ServiceCategories.financialAidAndScholarships;
      case 'IT_SUPPORT_SERVICES':
        return ServiceCategories.itSupportServices;
      case 'CAREER_GUIDANCE_AND_COUNSELING':
        return ServiceCategories.careerGuidanceAndCounseling;
      case 'STUDENT_AFFAIRS_AND_EXTRACURRICULAR_ACTIVITIES':
        return ServiceCategories.studentAffairsAndExtracurricularActivities;
      case 'SECURITY_AND_CAMPUS_SAFETY':
        return ServiceCategories.securityAndCampusSafety;
      case 'MAINTENANCE_AND_FACILITIES_MANAGEMENT':
        return ServiceCategories.maintenanceAndFacilitiesManagement;
      case 'PARKING_SERVICES':
        return ServiceCategories.parkingServices;
      case 'PRINTING_AND_PHOTOCOPYING_SERVICES':
        return ServiceCategories.printingAndPhotocopyingServices;
      case 'BOOKSTORE_SERVICES':
        return ServiceCategories.bookstoreServices;
      case 'ALUMNI_RELATIONS_OFFICE':
        return ServiceCategories.alumniRelationsOffice;
      default:
        throw ArgumentError('Unknown ServiceCategory key: $key');
    }
  }
}