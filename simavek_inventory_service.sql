simavek_inventory_service.sql


CREATE TABLE IF NOT EXISTS medicines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    category VARCHAR(100) NOT NULL,
    stock INTEGER DEFAULT 0 CHECK (stock >= 0),
    min_stock INTEGER DEFAULT 10,
    price DECIMAL(10, 2) NOT NULL CHECK (price >= 0),
    expired_date DATE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS stock_movements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    medicine_id UUID REFERENCES medicines(id) ON DELETE CASCADE,
    quantity_change INTEGER NOT NULL,
    movement_type VARCHAR(50) NOT NULL CHECK (movement_type IN ('PURCHASE', 'SALE', 'RETURN', 'EXPIRED', 'ADJUSTMENT')),
    reference_id VARCHAR(255),
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);


CREATE INDEX IF NOT EXISTS idx_stock_movements_medicine ON stock_movements(medicine_id);
CREATE INDEX IF NOT EXISTS idx_medicines_low_stock ON medicines(stock, min_stock);


CREATE OR REPLACE FUNCTION update_medicine_stock(
    p_medicine_id UUID,
    p_quantity INTEGER,
    p_movement_type VARCHAR,
    p_reference_id VARCHAR,
    p_notes TEXT DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    v_current_stock INTEGER;
    v_new_stock INTEGER;
    v_medicine_name VARCHAR;
BEGIN
    SELECT stock, name INTO v_current_stock, v_medicine_name
    FROM medicines 
    WHERE id = p_medicine_id 
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Medicine with ID % not found', p_medicine_id;
    END IF;

    v_new_stock := v_current_stock + p_quantity;

    IF v_new_stock < 0 THEN
        RAISE EXCEPTION 'Insufficient stock. Current: %, Requested: %, Medicine: %', 
            v_current_stock, ABS(p_quantity), v_medicine_name;
    END IF;

    -- Update stok utama
    UPDATE medicines 
    SET stock = v_new_stock, updated_at = NOW()
    WHERE id = p_medicine_id;

    -- Catat riwayat pergerakan stok
    INSERT INTO stock_movements (medicine_id, quantity_change, movement_type, reference_id, notes)
    VALUES (p_medicine_id, p_quantity, p_movement_type, p_reference_id, p_notes);

    -- Kembalikan respons JSON
    RETURN json_build_object(
        'success', true,
        'medicine_id', p_medicine_id,
        'medicine_name', v_medicine_name,
        'previous_stock', v_current_stock,
        'new_stock', v_new_stock,
        'quantity_changed', p_quantity
    );
END;
$$ LANGUAGE plpgsql;
