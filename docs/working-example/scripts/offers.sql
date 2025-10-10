CREATE TABLE offers (
    offer_id VARCHAR(16) PRIMARY KEY,
    offer_details TEXT NOT NULL,
    card_type VARCHAR(10) NOT NULL,          -- 'credit' or 'debit'
    bank_name VARCHAR(64) NOT NULL,
    provider_type VARCHAR(20) NOT NULL,      -- 'Visa', 'MasterCard', 'RuPay', 'Amex', etc.
    emi_available BOOLEAN,
    cashback_value NUMERIC(10,2) NOT NULL,   -- Cashback value (percentage or flat)
    cashback_type VARCHAR(16) NOT NULL,      -- 'percentage' or 'flat'
    cashback_max NUMERIC(10,2)               -- Max cashback if type is 'percentage', NULL for flat
);

-- Sample data
INSERT INTO offers (offer_id, offer_details, card_type, bank_name, provider_type, emi_available, cashback_value, cashback_type, cashback_max) VALUES
('ORD1', '10% cashback on Yes Bank Visa Credit Cards', 'credit', 'Yes Bank', 'Visa', FALSE, 10, 'percentage', 500),
('ORD2', 'Flat ₹150 cashback on Kotak Mahindra Bank Amex Debit Cards', 'debit', 'Kotak Mahindra Bank', 'Amex', NULL, 150, 'flat', NULL),
('ORD3', '7% cashback (up to ₹400) on Yes Bank Amex Credit Cards', 'credit', 'Yes Bank', 'Amex', TRUE, 7, 'percentage', 400),
('ORD4', 'Flat ₹500 cashback for HDFC MasterCard Credit Cards', 'credit', 'HDFC Bank', 'MasterCard', TRUE, 500, 'flat', NULL),
('ORD5', '2% cashback (up to ₹200) on ICICI Bank RuPay Debit', 'debit', 'ICICI Bank', 'RuPay', NULL, 2, 'percentage', 200),
('ORD6', 'Flat ₹100 cashback with Axis Bank Visa Credit', 'credit', 'Axis Bank', 'Visa', TRUE, 100, 'flat', NULL),
('ORD7', '9% cashback (up to ₹400) on Yes Bank Amex Debit', 'debit', 'Yes Bank', 'Amex', NULL, 9, 'percentage', 400),
('ORD8', 'Flat ₹25 cashback on Axis Bank RuPay Debit', 'debit', 'Axis Bank', 'RuPay', NULL, 25, 'flat', NULL),
('ORD9', '4% cashback (up to ₹100) on HDFC Visa Debit', 'debit', 'HDFC Bank', 'Visa', NULL, 4, 'percentage', 100),
('ORD10', 'Flat ₹250 cashback for ICICI MasterCard Credit', 'credit', 'ICICI Bank', 'MasterCard', TRUE, 250, 'flat', NULL);