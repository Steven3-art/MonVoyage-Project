import os
from dotenv import load_dotenv
from sqlmodel import SQLModel, create_engine, Field, Session, select
from typing import Optional
from datetime import datetime, timedelta

# Load environment variables
load_dotenv()

# Database Configuration
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./database.db")
engine = create_engine(DATABASE_URL, echo=True)

# --- MODELS (Copied from voyage.py for table creation) ---
class User(SQLModel, table=True, extend_existing=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    username: str = Field(index=True, unique=True)
    hashed_password: str
    email: Optional[str] = Field(default=None, index=True, unique=True)
    is_active: bool = Field(default=True)

class Ticket(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    notchpay_reference: str = Field(index=True)
    status: str = Field(default="pending")
    amount: int
    currency: str = "XAF"
    email: str
    phone: str
    description: str
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

class VehicleLocation(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    vehicle_id: str = Field(index=True, unique=True)
    latitude: float
    longitude: float
    timestamp: datetime = Field(default_factory=datetime.utcnow)

# --- Function to create tables ---
def create_db_and_tables():
    print("Attempting to create database tables...")
    SQLModel.metadata.create_all(engine)
    print("Database tables created (or already exist).")

if __name__ == "__main__":
    create_db_and_tables()
