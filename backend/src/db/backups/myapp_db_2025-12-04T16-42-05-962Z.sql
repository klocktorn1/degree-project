-- MySQL dump 10.13  Distrib 8.0.44, for Linux (x86_64)
--
-- Host: localhost    Database: degree_project
-- ------------------------------------------------------
-- Server version	8.0.44-0ubuntu0.24.04.1

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `exercise_results`
--

DROP TABLE IF EXISTS `exercise_results`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `exercise_results` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `exercise_id` int NOT NULL,
  `score` int DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `completed_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  KEY `exercise_id` (`exercise_id`),
  CONSTRAINT `exercise_results_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  CONSTRAINT `exercise_results_ibfk_2` FOREIGN KEY (`exercise_id`) REFERENCES `exercises` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `exercise_results`
--

LOCK TABLES `exercise_results` WRITE;
/*!40000 ALTER TABLE `exercise_results` DISABLE KEYS */;
/*!40000 ALTER TABLE `exercise_results` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `exercises`
--

DROP TABLE IF EXISTS `exercises`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `exercises` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `description` text NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `exercises`
--

LOCK TABLES `exercises` WRITE;
/*!40000 ALTER TABLE `exercises` DISABLE KEYS */;
INSERT INTO `exercises` VALUES (1,'asd','asd'),(2,'asd','asd');
/*!40000 ALTER TABLE `exercises` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `password_resets`
--

DROP TABLE IF EXISTS `password_resets`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `password_resets` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `token` varchar(64) NOT NULL,
  `expires_at` datetime NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `token` (`token`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `password_resets_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `password_resets`
--

LOCK TABLES `password_resets` WRITE;
/*!40000 ALTER TABLE `password_resets` DISABLE KEYS */;
INSERT INTO `password_resets` VALUES (1,15,'$2b$12$KtrLPossHJvLoP4IFj.EPewCvaXfPpXsfMBmNQbfr/GdbaRoqMpZq','2025-12-04 18:34:55','2025-12-04 16:34:54'),(2,15,'bbb3e848724afbaeeed8d176531afb679a9640e0d8e3aacda3c92d38b840717e','2025-12-04 18:35:44','2025-12-04 16:35:43'),(3,15,'6c2b2b51b83bd0f07f5a270dc5e151b6183e17bba6854db810c58acba0cc137e','2025-12-04 18:37:15','2025-12-04 16:37:14'),(4,15,'b3b82a0445b36cef1c36dbacbad911aa94454a8d8028762fa8186dd4365374ba','2025-12-04 18:38:03','2025-12-04 16:38:02'),(5,15,'68dc57b85e52330984a453f9f2f47bc09c8b7c919808e8aa75659c844d0c827e','2025-12-04 18:38:31','2025-12-04 16:38:30'),(6,15,'3dbf2a976d176f488494cd07769b6fd6890ea0a91591d43b885651006a4b3eaa','2025-12-04 18:39:23','2025-12-04 16:39:22');
/*!40000 ALTER TABLE `password_resets` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `id` int NOT NULL AUTO_INCREMENT,
  `username` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `firstname` varchar(255) NOT NULL,
  `lastname` varchar(255) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `refresh_token` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (1,'User1','asd@gmail.com','John','Smith','asd123','','2025-12-04 11:01:00'),(2,'User2','asd2@gmail.com','John','Smith','asd123','','2025-12-04 11:13:39'),(4,'User3','asd3@gmail.com','John','Smith','asd123','','2025-12-04 11:16:09'),(5,'User4','asd4@gmail.com','John','Smith','asd123','','2025-12-04 11:16:48'),(6,'User5','asd5@gmail.com','John','Smith','asd123','','2025-12-04 11:18:37'),(7,'Updated username','asd6@gmail.com','John','Smith','$2b$12$4H5Tx8Sr6L6MkrFoe0tIaeauL/srWp8xPeP4JT7sKT1jcmed9v6zi','','2025-12-04 11:19:13'),(8,'asdasdasd','asdasdasd6@gmail.com','John','Smith','$2b$12$rCJyMQVpIdFrXLRgHJicZeiHdWv0TcciiGGA8p/mSIkml8wPS9Xia','','2025-12-04 12:35:05'),(11,'asdasdasdasd','asdasdasdasd6@gmail.com','John','Smith','$2b$12$r4y0iDD/8VBdSg4WKCM3Ye.QeUk/j4SPCX2n0Hx57UP3iLUWz1.22','eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyIjoxMSwiZW1haWwiOiJhc2Rhc2Rhc2Rhc2Q2QGdtYWlsLmNvbSIsImlhdCI6MTc2NDg2MTEyOSwiZXhwIjoxNzY1NDY1OTI5fQ.pb-PFhHhW531Kuif0XrTuKvMICWWzO8nz_hxgRwNuKQ','2025-12-04 13:16:32'),(15,'Nickasd','snownicholas2@gmail.com','John','Smith','$2b$12$cnXzvhFJSDAToJTaDJbQMeYIvVkx1G477Qqv5Fx.KsjHIjhyrbptu','eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyIjoxNSwiZW1haWwiOiJzbm93bmljaG9sYXMyQGdtYWlsLmNvbSIsImlhdCI6MTc2NDg2NTMxMCwiZXhwIjoxNzY1NDcwMTEwfQ.cRQN2E4F1jLrgldh1vrqSTlVjQswuYv5X82x4Z49a3I','2025-12-04 16:21:36');
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2025-12-04 17:42:06
