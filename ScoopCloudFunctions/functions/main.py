# Welcome to Cloud Functions for Firebase for Python!
# To get started, simply uncomment the below code or create your own.

# The Cloud Functions for Firebase SDK to create Cloud Functions and set up triggers.
from firebase_functions import firestore_fn, https_fn

# The Firebase Admin SDK to access Cloud Firestore.
from firebase_admin import initialize_app, firestore, db
import google.cloud.firestore

app = initialize_app()



