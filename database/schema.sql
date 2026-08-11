-- AutoIntel reference schema (SQLAlchemy models are the source of truth;
-- this file is for quick review / manual psql inspection)

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    firebase_uid TEXT UNIQUE NOT NULL,
    email TEXT NOT NULL,
    display_name TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE vehicles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    make TEXT NOT NULL,
    model TEXT NOT NULL,
    year INT NOT NULL,
    vin TEXT,
    nickname TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_vehicles_user_id ON vehicles(user_id);

CREATE TABLE diagnostic_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    vehicle_id UUID NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
    started_at TIMESTAMPTZ NOT NULL,
    ended_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_sessions_vehicle_id ON diagnostic_sessions(vehicle_id);

CREATE TABLE fault_codes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID NOT NULL REFERENCES diagnostic_sessions(id) ON DELETE CASCADE,
    code TEXT NOT NULL,
    raw_description TEXT,
    ai_explanation TEXT,
    severity TEXT,
    status TEXT DEFAULT 'active',
    created_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_fault_codes_session_id ON fault_codes(session_id);

CREATE TABLE sensor_readings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID NOT NULL REFERENCES diagnostic_sessions(id) ON DELETE CASCADE,
    pid TEXT NOT NULL,
    value NUMERIC NOT NULL,
    unit TEXT,
    recorded_at TIMESTAMPTZ NOT NULL
);
CREATE INDEX idx_sensor_readings_session_id ON sensor_readings(session_id);
CREATE INDEX idx_sensor_readings_recorded_at ON sensor_readings(recorded_at);

CREATE TABLE maintenance_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    vehicle_id UUID NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    cost NUMERIC,
    odometer INT,
    notes TEXT,
    performed_at DATE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_maintenance_vehicle_id ON maintenance_logs(vehicle_id);

CREATE TABLE fuel_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    vehicle_id UUID NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
    liters_or_gallons NUMERIC NOT NULL,
    cost NUMERIC,
    odometer INT,
    recorded_at DATE NOT NULL
);
CREATE INDEX idx_fuel_vehicle_id ON fuel_logs(vehicle_id);
