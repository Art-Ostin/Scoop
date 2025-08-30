

from firebase_functions import firestore_fn, options
from firebase_admin import initialize_app, firestore

options.set_global_options(region="us-central1")

initialize_app()


@firestore_fn.on_document_created(document="users/{userId}/recommendation_cycles/{cycleId}")
def recommendation_cycle_created(event: firestore_fn.Event[firestore_fn.DocumentSnapshot]) -> None: 
    snap = event.data 
    let end_time = snap.get("endsAt")


def recommendation_cycle_created(event: firestore_fn.Event[firestore_fn.DocumentSnapshot]) -> None:
    snap = event.data
    cycle = snap.to_dict() if snap else {}
    user_id = event.params["userId"] 


