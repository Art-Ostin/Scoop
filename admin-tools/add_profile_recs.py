import os
import firebase_admin
from firebase_admin import credentials, firestore
import profile_rec

key_path = os.environ["GOOGLE_APPLICATION_CREDENTIALS"]
cred = credentials.Certificate(key_path) 
firebase_admin.initialize_app(cred)                      
db = firestore.client()


def add_profile_recommendations(user_id,profile_id):

    doc_ref = db.collection('users').document(user_id).collection('profiles').document(profile_id)
    profile_rec = profile_rec.ProfileRec()

    doc_ref.set({
        "profileRec": {
            "status": profile_rec.status,
            "profileViews": profile_rec.profileViews,
            "added_day": firestore.SERVER_TIMESTAMP,
            "updated_day": firestore.SERVER_TIMESTAMP,
        }
    }, merge=True)


print("hello world")