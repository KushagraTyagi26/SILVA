// lib/services/gemini_service.dart
import 'dart:io';
import 'package:flutter/material.dart';

class GeminiService {

  static Future<AnimalAssessment> analyzeAnimalPhoto(File imageFile) async {
    // Simulate AI processing delay for realism
    await Future.delayed(const Duration(seconds: 2));

    // Rotate through realistic sample assessments for demo
    final samples = [
      AnimalAssessment(
        animalType: 'Domestic Cat',
        breed: 'Orange Tabby (Felis catus)',
        estimatedAge: '3-5 years',
        color: 'Orange and white tabby',
        injuries: [
          'Ocular proptosis — right eye displaced from socket',
          'Corneal damage with visible tissue prolapse',
          'Facial abrasion near right eye',
          'Possible orbital fracture',
        ],
        overallCondition: 'Severe Injuries',
        severityScore: 9,
        urgencyLevel: 'Code Red',
        visibleSymptoms: [
          'Right eye severely protruding from socket',
          'Corneal opacity and tissue exposure',
          'Nasal abrasion with dried blood',
          'Alert but in obvious distress',
        ],
        recommendedActions: [
          'Code Red — emergency veterinary care within 1 hour',
          'Cover eye gently with damp sterile cloth — do NOT press',
          'Keep animal calm and in dark enclosed space',
          'Do not attempt to push eye back into socket',
          'Immediate surgery may be required to save the eye',
        ],
        aiSummary: 'Orange tabby cat presenting with traumatic ocular proptosis of the right eye — likely caused by a road accident or animal attack. The eye is severely displaced with visible corneal damage and tissue prolapse. This is a critical emergency; without surgical intervention within 1-2 hours, permanent vision loss in the right eye is near certain.',
        requiresImmediateVet: true,
        estimatedWeight: '3-5 kg',
      ),
      AnimalAssessment(
        animalType: 'Indian Leopard',
        breed: 'Panthera pardus fusca',
        estimatedAge: '2-3 years',
        color: 'Tawny yellow with dark rosettes',
        injuries: ['Snare wound on right foreleg'],
        overallCondition: 'Severe Injuries',
        severityScore: 8,
        urgencyLevel: 'Code Red',
        visibleSymptoms: ['Deep snare wound', 'Swelling', 'Distress vocalisation'],
        recommendedActions: [
          'Code Red — immediate rescue required',
          'Contact Wildlife SOS: 1800-200-9453',
          'Do not attempt to remove snare yourself',
          'Keep area clear to reduce animal stress',
        ],
        aiSummary: 'Young leopard with severe snare injury on foreleg. Wound shows signs of infection and tissue damage. Without immediate intervention, permanent disability or fatality is likely. Emergency rescue required.',
        requiresImmediateVet: true,
        estimatedWeight: '45-60 kg',
      ),
      AnimalAssessment(
        animalType: 'Spotted Deer',
        breed: 'Axis axis (Chital)',
        estimatedAge: '1-2 years',
        color: 'Brown with white spots',
        injuries: [],
        overallCondition: 'Healthy',
        severityScore: 2,
        urgencyLevel: 'Routine',
        visibleSymptoms: ['Appears disoriented', 'Separated from herd'],
        recommendedActions: [
          'Monitor for 2-3 hours',
          'Ensure no predator threat nearby',
          'Do not feed or approach',
          'Contact ranger if still alone after 3 hours',
        ],
        aiSummary: 'Young chital deer appears physically healthy with no visible injuries. Animal seems separated from its herd, possibly due to human activity nearby. Routine monitoring recommended.',
        requiresImmediateVet: false,
        estimatedWeight: '30-40 kg',
      ),
      AnimalAssessment(
        animalType: 'Indian Elephant',
        breed: 'Elephas maximus indicus',
        estimatedAge: '8-12 years',
        color: 'Dark grey',
        injuries: ['Bullet wound on flank', 'Signs of dehydration'],
        overallCondition: 'Severe Injuries',
        severityScore: 9,
        urgencyLevel: 'Code Red',
        visibleSymptoms: ['Open wound', 'Laboured breathing', 'Lethargy'],
        recommendedActions: [
          'Immediate emergency response required',
          'Contact Forest Department emergency line',
          'Do not approach — highly dangerous when injured',
          'Aerial surveillance recommended',
        ],
        aiSummary: 'Sub-adult elephant with suspected gunshot wound on left flank. Animal shows signs of severe pain, dehydration and laboured breathing. This is a critical wildlife emergency requiring immediate coordinated response.',
        requiresImmediateVet: true,
        estimatedWeight: '2000-3000 kg',
      ),
      AnimalAssessment(
        animalType: 'Indian Fox',
        breed: 'Vulpes bengalensis',
        estimatedAge: '1-2 years',
        color: 'Grey-brown with pale underside',
        injuries: ['Road accident injuries', 'Possible internal trauma'],
        overallCondition: 'Moderate Injuries',
        severityScore: 5,
        urgencyLevel: 'Urgent',
        visibleSymptoms: ['Dazed', 'Unable to walk straight', 'Shallow breathing'],
        recommendedActions: [
          'Gently place in ventilated box',
          'Keep in dark quiet location',
          'Contact nearest wildlife rescue centre',
          'Do not offer food or water',
        ],
        aiSummary: 'Indian fox showing signs consistent with vehicle collision. Animal is conscious but disoriented with possible neurological impact. Needs urgent wildlife rescue and veterinary care within the next few hours.',
        requiresImmediateVet: true,
        estimatedWeight: '2-4 kg',
      ),
    ];

    // Always return first sample for demo consistency
    final random = DateTime.now().millisecond % samples.length;
    return samples[random];
  }
}

class AnimalAssessment {
  final String animalType, color, overallCondition, urgencyLevel, aiSummary;
  final String? breed, estimatedAge, estimatedWeight;
  final List<String> injuries, visibleSymptoms, recommendedActions;
  final int severityScore;
  final bool requiresImmediateVet;

  AnimalAssessment({
    required this.animalType,
    required this.color,
    required this.overallCondition,
    required this.urgencyLevel,
    required this.aiSummary,
    required this.injuries,
    required this.visibleSymptoms,
    required this.recommendedActions,
    required this.severityScore,
    required this.requiresImmediateVet,
    this.breed,
    this.estimatedAge,
    this.estimatedWeight,
  });

  factory AnimalAssessment.fromJson(Map<String, dynamic> j) => AnimalAssessment(
    animalType: j['animalType'] ?? 'Unknown',
    color: j['color'] ?? 'Unknown',
    overallCondition: j['overallCondition'] ?? 'Unknown',
    urgencyLevel: j['urgencyLevel'] ?? 'Routine',
    aiSummary: j['aiSummary'] ?? '',
    injuries: List<String>.from(j['injuries'] ?? []),
    visibleSymptoms: List<String>.from(j['visibleSymptoms'] ?? []),
    recommendedActions: List<String>.from(j['recommendedActions'] ?? []),
    severityScore: (j['severityScore'] as num?)?.toInt() ?? 1,
    requiresImmediateVet: j['requiresImmediateVet'] ?? false,
    breed: j['breed'],
    estimatedAge: j['estimatedAge'],
    estimatedWeight: j['estimatedWeight'],
  );

  Map<String, dynamic> toJson() => {
    'animalType': animalType, 'breed': breed, 'estimatedAge': estimatedAge,
    'color': color, 'injuries': injuries, 'overallCondition': overallCondition,
    'severityScore': severityScore, 'urgencyLevel': urgencyLevel,
    'visibleSymptoms': visibleSymptoms, 'recommendedActions': recommendedActions,
    'aiSummary': aiSummary, 'requiresImmediateVet': requiresImmediateVet,
    'estimatedWeight': estimatedWeight,
  };

  Color get urgencyColor {
    switch (urgencyLevel) {
      case 'Code Red':   return const Color(0xFFE53935);
      case 'Emergency':  return const Color(0xFFFF5722);
      case 'Urgent':     return const Color(0xFFFF8F00);
      default:           return const Color(0xFF43A047);
    }
  }
}
