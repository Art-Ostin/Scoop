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

for snap in user_snaps:
    ids_to_add.append(snap.id)


def add_profile_recommendations(user_id, profile_id):
    if user_id != profile_id: 
        doc_ref = db.collection('users').document(user_id).collection('profiles').document(profile_id)
        profile_rec = ProfileRec()
        doc_ref.set({
            "status": profile_rec.status,
            "profileViews": profile_rec.profileViews,
            "added_day": firestore.SERVER_TIMESTAMP,
            "updated_day": firestore.SERVER_TIMESTAMP,
        }, merge=True)


for profile_id in ids_to_add:
    add_profile_recommendations("kGSjxlpXy4WmgKHZR9GPPVU2xjb2", profile_id)


