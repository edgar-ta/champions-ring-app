import type {
  DocumentData,
  DocumentReference,
} from "firebase-admin/firestore";
import {CoreDate} from "./core_date.js";
import {FirestoreEntity} from "./firestore_entity.js";
import {
  readBoolean,
  readDate,
  readOptionalBoolean,
  readOptionalDate,
  readOptionalReference,
  readOptionalString,
  readString,
  readUid,
} from "./firestore_values.js";

/** Member profile stored in the members collection. */
export class CoreMember extends FirestoreEntity {
  /** Creates a member profile. */
  constructor(
    readonly uid: string,
    readonly birthDate: CoreDate,
    readonly phone: string,
    readonly legalDataAreTheirs: boolean,
    readonly inscriptionPaid: boolean,
    readonly ineBackUrl: string,
    readonly ineBackValidated: boolean,
    readonly ineFrontUrl: string,
    readonly ineFrontValidated: boolean,
    readonly creationDate: CoreDate,
    readonly photoUrl?: string,
    readonly membershipPlanRef?: DocumentReference,
    readonly latestRenewalRef?: DocumentReference,
    readonly guardianName?: string,
    readonly guardianPhone?: string,
    readonly guardianRelationship?: string,
    readonly curpUrl?: string,
    readonly curpValidated?: boolean,
    readonly waiverAgreementUrl?: string,
    readonly waiverAgreementValidated?: boolean,
    readonly deletionDate?: CoreDate
  ) {
    super();
  }

  /**
   * Converts this member to its Firestore representation.
   * @return {DocumentData} Firestore document data.
   */
  toFirestore(): DocumentData {
    return {
      uid: this.uid,
      birthDate: this.birthDate.toFirebaseValue(),
      phone: this.phone,
      legalDataAreTheirs: this.legalDataAreTheirs,
      inscriptionPaid: this.inscriptionPaid,
      ineBackUrl: this.ineBackUrl,
      ineBackValidated: this.ineBackValidated,
      ineFrontUrl: this.ineFrontUrl,
      ineFrontValidated: this.ineFrontValidated,
      creationDate: this.creationDate.toFirebaseValue(),
      ...(this.photoUrl !== undefined ? {photoUrl: this.photoUrl} : {}),
      ...(this.membershipPlanRef ?
        {membershipPlanRef: this.membershipPlanRef} :
        {}),
      ...(this.latestRenewalRef ?
        {latestRenewalRef: this.latestRenewalRef} :
        {}),
      ...(this.guardianName !== undefined ?
        {guardianName: this.guardianName} :
        {}),
      ...(this.guardianPhone !== undefined ?
        {guardianPhone: this.guardianPhone} :
        {}),
      ...(this.guardianRelationship !== undefined ?
        {guardianRelationship: this.guardianRelationship} :
        {}),
      ...(this.curpUrl !== undefined ? {curpUrl: this.curpUrl} : {}),
      ...(this.curpValidated !== undefined ?
        {curpValidated: this.curpValidated} :
        {}),
      ...(this.waiverAgreementUrl !== undefined ?
        {waiverAgreementUrl: this.waiverAgreementUrl} :
        {}),
      ...(this.waiverAgreementValidated !== undefined ?
        {waiverAgreementValidated: this.waiverAgreementValidated} :
        {}),
      ...(this.deletionDate ?
        {deletionDate: this.deletionDate.toFirebaseValue()} :
        {}),
    };
  }

  /**
   * Creates a member from a Firestore document.
   * @param {DocumentData} data Firestore document data.
   * @param {string} [documentId] Firestore document id fallback.
   * @return {CoreMember} Decoded member.
   */
  static fromFirestore(data: DocumentData, documentId?: string): CoreMember {
    return new CoreMember(
      readUid(data, documentId),
      readDate(data, "birthDate"),
      readString(data, "phone"),
      readBoolean(data, "legalDataAreTheirs"),
      readBoolean(data, "inscriptionPaid", "inscriptionPayed"),
      readString(data, "ineBackUrl"),
      readBoolean(data, "ineBackValidated"),
      readString(data, "ineFrontUrl"),
      readBoolean(data, "ineFrontValidated"),
      readDate(data, "creationDate"),
      readOptionalString(data, "photoUrl"),
      readOptionalReference(data, "membershipPlanRef"),
      readOptionalReference(data, "latestRenewalRef"),
      readOptionalString(data, "guardianName"),
      readOptionalString(data, "guardianPhone"),
      readOptionalString(data, "guardianRelationship"),
      readOptionalString(data, "curpUrl"),
      readOptionalBoolean(data, "curpValidated"),
      readOptionalString(data, "waiverAgreementUrl"),
      readOptionalBoolean(data, "waiverAgreementValidated"),
      readOptionalDate(data, "deletionDate")
    );
  }
}
