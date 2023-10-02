SELECT * FROM healthcare.keep;
ALTER TABLE keep
ADD FOREIGN KEY (pharmacyID) REFERENCES pharmacy(pharmacyID);

ALTER TABLE keep
ADD FOREIGN KEY (medicineID) REFERENCES medicine(medicineID);
ALTER TABLE contain
ADD FOREIGN KEY (prescriptionID) REFERENCES prescription(prescriptionID);


ALTER TABLE claim
ADD FOREIGN KEY (uin) REFERENCES insuranceplan(uin);