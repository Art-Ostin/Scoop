import os
from dataclasses import dataclass
from enum import Enum
from typing import Optional

import firebase_admin
from firebase_admin import credentials, firestore
from google.api_core.exceptions import AlreadyExists

key_path = os.environ["GOOGLE_APPLICATION_CREDENTIALS"]  # fails clearly if not set
cred = credentials.Certificate(key_path)                 # loads the service account JSON

for user in user_snaps:
    ids.append(user.id)

class Status(str, Enum):
    pending = "pending"
    invited = "invited"
    declined = "declined"
    invitedDeclined = "invitedDeclined"
    invitedAccepted = "invitedAccepted"

@dataclass(frozen=True)
class ProfileRec:
    profileViews: int = 0
    status: Status = Status.pending
    actedAt: Optional[firestore.Timestamp] = None

    def to_dict(self, include_added_day: bool = True) -> dict:
        data = {
            "profileViews": self.profileViews,
            "status": self.status.value,
        }
        if include_added_day:
            data["addedDay"] = firestore.SERVER_TIMESTAMP
        if self.actedAt is not None:
            data["actedAt"] = self.actedAt
        return data

def give_user_profile_recs(user_id): 
    profiles_ref = db.collection('users').document(user_id).collection('profiles')
    rec = ProfileRec()
            doc_ref = profiles_ref.document(id)
        try:
            doc_ref.create(rec.to_dict())
        except AlreadyExists:
            pass


