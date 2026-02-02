import os
import firebase_admin
from firebase_admin import credentials, firestore

key_path = os.environ["GOOGLE_APPLICATION_CREDENTIALS"]  # fails clearly if not set
cred = credentials.Certificate(key_path)                 # loads the service account JSON
firebase_admin.initialize_app(cred)                      # initializes Admin SDK
db = firestore.client()                                  # Firestore client

user_snaps = list(db.collection('users').limit(5).stream())

ids = []

for user in user_snaps:
    ids.append(user.id)

def give_user_profile_recs(user_id): 
    profiles_ref = db.collection('users').document(user_id).collection('profiles')

    for id in ids:
            profiles_ref.document(id).set({
                "status": "pending",
                "profileViews": 0
            }, merge=True)

give_user_profile_recs("kGSjxlpXy4WmgKHZR9GPPVU2xjb2")

print("Hello World T")