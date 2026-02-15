import os
import firebase_admin
from firebase_admin import credentials, firestore
from profile_rec import ProfileRec

key_path = os.environ["GOOGLE_APPLICATION_CREDENTIALS"]
cred = credentials.Certificate(key_path) 
firebase_admin.initialize_app(cred)                      
db = firestore.client()


ids_to_add = []

user_snaps = db.collection('users').limit(10).stream()
print("IDs fetched:", len(ids_to_add), ids_to_add)

for snap in user_snaps:
    ids_to_add.append(snap.id)


def add_profile_recommendations(user_id, profile_id):
    if user_id != profile_id: 
        doc_ref = db.collection('users').document(user_id).collection('profiles').document(profile_id)
        profile_rec = ProfileRec()
        doc_ref.set({
            "status": profile_rec.status,
            "profileViews": profile_rec.profileViews,
            "addedDay": firestore.SERVER_TIMESTAMP,
            "updatedDay": firestore.SERVER_TIMESTAMP,
        }, merge=True)


for profile_id in ids_to_add:
    print("Starting…")
    add_profile_recommendations("VweZmx8DUoOuNG3EEsv5qOUbQ1i1", profile_id)


