

class ProfileRec: 
    
    PENDING = "pending"
    INVITED = "invited"
    DECLINED = "declined"
    INVITED_DECLINED = "invitedDeclined"
    INVITED_ACCEPTED = "invitedAccepted"
    
    def __init__(self, status = PENDING, profileViews = 0): 
        self.status = status
        self.profileViews = profileViews
    
    
    def to_dict(self):
        return {
            "status": self.status,
            "profileViews": self.profileViews,
            "added_day": self.added_day,
            "acted_at": self.acted_at,
        }
