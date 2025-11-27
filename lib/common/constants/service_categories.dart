/// Service category definitions and helpers.
///
/// This module provides:
/// - [ServiceCategories] enum: strongly typed categories used across the app.
/// - [ServiceCategoryLabel] extension: human–readable labels for UI.
/// - [ServiceCategoryKey] extension: backend-safe keys that match the Amplify
///   GraphQL schema enum (UPPER_SNAKE_CASE).
/// - [ServiceCategoryParser] extension: parser to convert backend enum strings
///   back into [ServiceCategories] values.
///
/// Design goals:
/// - Single source of truth for all categories to avoid string duplication.
/// - Strong typing in Dart code instead of passing raw strings around.
/// - Clean separation between:
///   - what the user sees (label)
///   - what the backend expects (key)
/// - Easy roundtrip: enum -> key -> enum.
enum ServiceCategories {
  /// Transportation services provided to students
  studentTransportationServices,

  /// On-campus or university-managed food providers
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

  /// Registration & admissions services.
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

  /// Maintenance and facilities management services
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

/// UI label for dropdowns, buttons, chips, etc.
///
/// Example:
/// ```dart
/// final category = ServiceCategories.foodServices;
/// print(category.label); // "Food Services"
/// ```
///
/// This keeps UI text centralized and avoids scattering hard-coded strings
/// across widgets. If the wording needs to change, we update it once here.
extension ServiceCategoryLabel on ServiceCategories {
  /// Human–readable label for this service category.
  ///
  /// Intended usage:
  /// - Dropdown menus
  /// - Any UI surface where the user needs to recognize the category.
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

/// Backend key (UPPER_SNAKE_CASE) matching the Amplify GraphQL enum
/// `ServiceCategory` (or equivalent on the backend).
/// This isolates stringly-typed backend values to one place and allows the rest
/// of the codebase to use the strongly-typed [ServiceCategories] enum.
extension ServiceCategoryKey on ServiceCategories {
  /// Backend-safe enum key used in GraphQL operations.
  ///
  /// This MUST stay in sync with:
  /// - the GraphQL schema enum definition
  /// - any server-side switch/lookup on service category
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

/// Parser: convert backend enum string -> [ServiceCategories].
///
/// This is essentially the inverse of [ServiceCategoryKey.key].
///
/// Throws:
/// - [ArgumentError] if the key does not match any known category.
///   This is intentional to fail fast if the backend sends an unexpected value.
extension ServiceCategoryParser on ServiceCategories {
  /// Convert a backend enum key (UPPER_SNAKE_CASE) into a [ServiceCategories] value.
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
        // If we hit this case, backend and client are out of sync.
        // Failing fast here surfaces schema drift early during development.
        throw ArgumentError('Unknown ServiceCategory key: $key');
    }
  }
}
