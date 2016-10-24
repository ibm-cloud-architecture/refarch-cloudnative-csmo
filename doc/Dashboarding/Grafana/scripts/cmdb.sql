SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";


CREATE TABLE IF NOT EXISTS `cmdb` (
  `APPID` int(11) NOT NULL,
  `APPNAME` text NOT NULL,
  `APPTYPE` text NOT NULL,
  `REGIONNAME` text NOT NULL,
  `CLIENT` text NOT NULL,
  `DESCRIPTION` text,
  `SERVICENAME` text NOT NULL,
  `SERVICEID` text NOT NULL,
  `LOGMET_GRAFANA_ID` text
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


INSERT INTO `cmdb` (`APPID`, `APPNAME`, `APPTYPE`, `REGIONNAME`, `CLIENT`, `DESCRIPTION`, `SERVICENAME`, `SERVICEID`, `LOGMET_GRAFANA_ID`) VALUES
(30999680, 'HybridShopUI', '', 'bmx_us-south', 'foo', 'PHP component for OrderApp', 'HybridOrderApp', '1483', ''),
(30984725, 'CloudCatalogAPI', '', 'bmx_us-south', 'foo', 'CatalogAPI node.js component for OrderApp', 'HybridOrderApp', '1483', ''),
(23192303, 'Python Application', '', 'bmx_us-south', 'foo', 'Python component for OrderApp', 'HybridOrderApp', '1483', ''),
(30793439, 'hybrid-orders-mysql-on-SL', '', 'sl', 'foo', 'mysql component for OrderApp', 'HybridOrderApp', '1483', ''),
(23451234, 'hk-dbserver.casenation.com', '', 'sl', 'foo', 'mysql server for OrderApp', 'HybridOrderApp', '1483', ''),
(31935607, 'inventory-bff-app-dev', 'cf_app', 'bmx_eu-gb', 'CASE-DEV', 'Inventory BFF Node.js', 'BlueCompute', '1507', ''),
(31939678, 'bluecompute-web-app', 'cf_app', 'bmx_eu-gb', 'CASE-DEV', 'Bluecompute WebApp Node.js', 'BlueCompute', '1507', ''),
(123451234, 'instance-007f7485', '', 'bmx_eu-gb', 'CASE-DEV', 'mysql database server', 'BlueCompute', '1507', ''),
(123451235, 'instance-00811b46', '', 'sl_eu-gb', 'CASE-DEV', 'mysql server for OmniChannel', 'BlueCompute', '1507', ''),
(32528997, 'socialreview-bff-app', 'cf_app', 'bmx_eu-gb', 'CASE-DEV', 'Bluecompute SocialReview Node.js', 'BlueCompute', '1507', ''),
(123452231, 'bluecompute-apic-lb-nginx', 'container', 'bmx_eu-gb', 'CASE-DEV', 'single container', 'BlueCompute', '1507', '404aad37-5580-4320-8027-a9072bf95f01_98ed669c-dafd-4b5c-ad31-456d0aad7ad0'),
(123452235, 'micro-inventory-group', 'container', 'bmx_eu-gb', 'CASE-DEV', 'container group', 'BlueCompute', '1507', '404aad37-5580-4320-8027-a9072bf95f01_87a68fb6-1e88-4e7e-8af8-52cb3aebaf36'),
(123452237, 'micro-socialreview-group', 'container', 'bmx_eu-gb', 'CASE-DEV', 'container group', 'BlueCompute', '1507', '404aad37-5580-4320-8027-a9072bf95f01_9bb0a75b-b0f2-4509-9e94-1491ee60bcde'),
(123452238, 'zuul_cluster', 'container', 'bmx_eu-gb', 'CASE-DEV', 'container group', 'BlueCompute', '1507', '404aad37-5580-4320-8027-a9072bf95f01_73159730-bcb1-45a4-955f-70ff86c0da25'),
(123452239, 'eureka_cluster', 'container', 'bmx_eu-gb', 'CASE-DEV', 'container group', 'BlueCompute', '1507', '404aad37-5580-4320-8027-a9072bf95f01_41fbe088-7c67-4b3b-b67e-2dd72beb2f6e'),
(123453231, 'mysql-dal09-sqlnode1', 'mysql', 'sl_us', 'CASE-DEV', 'mysql instance', 'BlueCompute', '1507', ''),
(123453232, 'mysql-dal09-sqlnode2', 'mysql', 'sl_us', 'CASE-DEV', 'mysql instance', 'BlueCompute', '1507', ''),
(123453233, 'mysql-lon02-sqlnode1', 'mysql', 'sl_eu-gb', 'CASE-DEV', 'mysql instance', 'BlueCompute', '1507', ''),
(123453234, 'mysql-lon02-sqlnode2', 'mysql', 'sl_eu-gb', 'CASE-DEV', 'mysql instance', 'BlueCompute', '1507', ''),
(325289111, 'zuul-cluster-eu', 'container_app', 'bmx_eu-gb', 'CASE-DEV', 'Container app', 'BlueCompute', '1507', ''),
(325289112, 'eureka-cluster-eu', 'container_app', 'bmx_eu-gb', 'CASE-DEV', 'Container app', 'BlueCompute', '1507', ''),
(325289113, 'microservice-inventory-eu', 'container_app', 'bmx_eu-gb', 'CASE-DEV', 'Container app', 'BlueCompute', '1507', ''),
(325289114, 'micro-socialreview-cloudnative-qa', 'container_app', 'bmx_eu-gb', 'CASE-DEV', 'Container app', 'BlueCompute', '1507', ''),
(325289115, 'micro-inventory-cloudnative-qa', 'container_app', 'bmx_eu-gb', 'CASE-DEV', 'Container app', 'BlueCompute', '1507', ''),
(9999999, '271effdc9cca', '', 'sl_eu-gb', 'CASE-DEV', 'centOS for mysql-lon02-sqlnode2', 'BlueCompute', '1507', ''),
(123453237, 'nginx-lb', 'nginx-lb', 'sl_eu-gb', 'CASE-DEV', 'nginx load balancer', 'BlueCompute', '1507', '');

