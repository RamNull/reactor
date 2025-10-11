CREATE TABLE offers (
    offer_id VARCHAR(36) PRIMARY KEY,          -- Using 36 for UUID support
    offer_details TEXT NOT NULL,
    card_type VARCHAR(20) NOT NULL,           -- Matches CardType enum ('CREDIT', 'DEBIT')
    bank_name VARCHAR(64) NOT NULL,
    provider_type VARCHAR(20) NOT NULL,       -- Matches ProviderType enum ('VISA', 'MASTERCARD', 'RUPAY', 'AMEX', etc.)
    emi_available BOOLEAN NOT NULL DEFAULT FALSE,
   cashback_value DOUBLE PRECISION NOT NULL,
   cashback_type VARCHAR(20) NOT NULL,       -- Matches CashbackType enum ('PERCENTAGE', 'FLAT')
   cashback_max DOUBLE PRECISION
);

-- Sample data
INSERT INTO offers (offer_id, offer_details, card_type, bank_name, provider_type, emi_available, cashback_value, cashback_type, cashback_max) VALUES
('ORD1', '10% cashback on Yes Bank Visa Credit Cards', 'CREDIT', 'Yes Bank', 'VISA', FALSE, 10.00, 'PERCENTAGE', 500.00),
('ORD2', 'Flat ₹150 cashback on Kotak Mahindra Bank Amex Debit Cards', 'DEBIT', 'Kotak Mahindra Bank', 'AMEX', FALSE, 150.00, 'FLAT', NULL),
('ORD3', '7% cashback (up to ₹400) on Yes Bank Amex Credit Cards', 'CREDIT', 'Yes Bank', 'AMEX', TRUE, 7.00, 'PERCENTAGE', 400.00),
('ORD4', 'Flat ₹500 cashback for HDFC MasterCard Credit Cards', 'CREDIT', 'HDFC Bank', 'MASTERCARD', TRUE, 500.00, 'FLAT', NULL),
('ORD5', '2% cashback (up to ₹200) on ICICI Bank RuPay Debit', 'DEBIT', 'ICICI Bank', 'RUPAY', FALSE, 2.00, 'PERCENTAGE', 200.00),
('ORD6', 'Flat ₹100 cashback with Axis Bank Visa Credit', 'CREDIT', 'Axis Bank', 'VISA', TRUE, 100.00, 'FLAT', NULL),
('ORD7', '9% cashback (up to ₹400) on Yes Bank Amex Debit', 'DEBIT', 'Yes Bank', 'AMEX', FALSE, 9.00, 'PERCENTAGE', 400.00),
('ORD8', 'Flat ₹25 cashback on Axis Bank RuPay Debit', 'DEBIT', 'Axis Bank', 'RUPAY', FALSE, 25.00, 'FLAT', NULL),
('ORD9', '4% cashback (up to ₹100) on HDFC Visa Debit', 'DEBIT', 'HDFC Bank', 'VISA', FALSE, 4.00, 'PERCENTAGE', 100.00),
('ORD10', 'Flat ₹250 cashback for ICICI MasterCard Credit', 'CREDIT', 'ICICI Bank', 'MASTERCARD', TRUE, 250.00, 'FLAT', NULL);