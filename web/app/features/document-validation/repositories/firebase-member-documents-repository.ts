import { deleteField, doc, getDoc, onSnapshot, serverTimestamp, updateDoc } from "firebase/firestore";

import { COLLECTIONS, clientsCollection, membersCollection } from "@/app/core/firebase/collections";
import { db } from "@/app/core/firebase/firebase";
import type { Client } from "@/app/core/models/client";
import { hasPendingDocuments } from "@/app/core/models/member";
import { REJECTION_FIELDS, type MemberDocumentsRepository, type PendingMember } from "./member-documents-repository";

export const firebaseMemberDocumentsRepository: MemberDocumentsRepository = {
  watchPendingMembers(onChange, onError) {
    // El nombre y el correo del miembro viven en clients/{uid}; se leen una vez por miembro.
    const clients = new Map<string, Promise<Client | null>>();
    const clientOf = (uid: string) => {
      if (!clients.has(uid)) {
        clients.set(uid, getDoc(doc(clientsCollection(), uid)).then(snapshot => snapshot.data() ?? null).catch(() => null));
      }
      return clients.get(uid)!;
    };

    let revision = 0;
    const unsubscribe = onSnapshot(membersCollection(), async (snapshot) => {
      const current = ++revision;
      try {
        const members = snapshot.docs
          .map(document => ({ ...document.data(), uid: document.data().uid ?? document.id }))
          .filter(member => member.deletionDate == null && hasPendingDocuments(member))
          .sort((a, b) => (a.creationDate?.toMillis?.() ?? 0) - (b.creationDate?.toMillis?.() ?? 0));
        const result: PendingMember[] = await Promise.all(members.map(async member => ({ member, client: await clientOf(member.uid) })));
        if (current === revision) onChange(result);
      } catch (error) {
        if (current === revision) onError(error);
      }
    }, onError);

    return () => { revision++; unsubscribe(); };
  },

  async validate(memberUid, field) {
    await updateDoc(doc(membersCollection(), memberUid), { [field]: true, [REJECTION_FIELDS[field]]: deleteField() });
  },

  async reject(memberUid, field, comment, receptionistUid) {
    await updateDoc(doc(membersCollection(), memberUid), {
      [field]: false,
      [REJECTION_FIELDS[field]]: {
        comment: comment.trim(),
        date: serverTimestamp(),
        receptionistRef: doc(db, COLLECTIONS.receptionists, receptionistUid),
      },
    });
  },
};
