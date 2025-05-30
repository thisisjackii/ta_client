

userId <- request.user.id
transactionId <- request.params.id
IF transactionId IS NULL OR transactionId IS EMPTY THEN
  nextFunction(NEW Error("Transaction ID parameter is required."))
  RETURN
END IF

CALL transactionService.deleteUserTransaction(transactionId, userId) 

responseObject <- NEW StdClass 
responseObject.success <- TRUE 
response.status(204).send() 
RETURN 




existingTransaction <- CALL self.getTransactionById(transactionId, userId)
logger.info("Soft-deleting transaction " + transactionId + " for user " + userId)
CALL transactionRepository.softDelete(transactionId) 
RETURN

updateData <- NEW StdClass
updateData.deletedAt <- NEW Date() 

updateOptions <- NEW StdClass
updateOptions.where <- NEW StdClass
updateOptions.where.id <- id
updateOptions.data <- updateData
updateOptions.include <- transactionIncludeDefault 

dbRecord <- CALL Database.Transaction.update(updateOptions)
RETURN dbRecord 