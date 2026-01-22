// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Customer _$CustomerFromJson(Map<String, dynamic> json) => _Customer(
  id: json['id'] as String,
  companyName: json['company_name'] as String? ?? '',
  tallyLicense: json['tally_license'] as String?,
  tallySerialNo: json['tally_serial_no'] as String?,
  apiKey: json['api_key'] as String? ?? '',
  amcExpiryDate: json['amc_expiry_date'] == null
      ? null
      : DateTime.parse(json['amc_expiry_date'] as String),
  tssExpiryDate: json['tss_expiry_date'] == null
      ? null
      : DateTime.parse(json['tss_expiry_date'] as String),
  contactPerson: json['contact_person'] as String?,
  contactPhone: json['contact_phone'] as String?,
  contactPhoneNumbers: (json['contact_phone_numbers'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  contactEmail: json['contact_email'] as String?,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  pinnedNote: json['pinned_note'] as String?,
  tallyCustomizations: (json['tally_customizations'] as List<dynamic>?)
      ?.map((e) => e as Map<String, dynamic>)
      .toList(),
  secretEmail: json['secret_email'] as String?,
  accountantName: json['accountant_name'] as String?,
  accountantPhone: json['accountant_phone'] as String?,
  accountantEmail: json['accountant_email'] as String?,
  tallySoftwareHistory: (json['tally_software_history'] as List<dynamic>?)
      ?.map((e) => e as Map<String, dynamic>)
      .toList(),
);

Map<String, dynamic> _$CustomerToJson(_Customer instance) => <String, dynamic>{
  'id': instance.id,
  'company_name': instance.companyName,
  'tally_license': instance.tallyLicense,
  'tally_serial_no': instance.tallySerialNo,
  'api_key': instance.apiKey,
  'amc_expiry_date': instance.amcExpiryDate?.toIso8601String(),
  'tss_expiry_date': instance.tssExpiryDate?.toIso8601String(),
  'contact_person': instance.contactPerson,
  'contact_phone': instance.contactPhone,
  'contact_phone_numbers': instance.contactPhoneNumbers,
  'contact_email': instance.contactEmail,
  'created_at': instance.createdAt?.toIso8601String(),
  'pinned_note': instance.pinnedNote,
  'tally_customizations': instance.tallyCustomizations,
  'secret_email': instance.secretEmail,
  'accountant_name': instance.accountantName,
  'accountant_phone': instance.accountantPhone,
  'accountant_email': instance.accountantEmail,
  'tally_software_history': instance.tallySoftwareHistory,
};
