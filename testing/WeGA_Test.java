package test;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.URL;
import java.net.URLEncoder;
import java.util.StringTokenizer;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;

import com.thoughtworks.selenium.DefaultSelenium;
import com.thoughtworks.selenium.SeleneseTestCase;
import com.thoughtworks.selenium.SeleniumException;

public class WeGA_Test extends SeleneseTestCase {
	
	/********* Einstellungen *********/
	
	String dbHost = "localhost";	// Der Host der Datenbank (192.168.3.104 für Menotti,menotti.bib.hfm-detmold.de)
	String dbProto = "http";
	String dbSubFolder = "/apps/WeGA-WebApp/";
	String seHost = "localhost";	// Der Selenium-Host (muss nicht derselbe sein wie DB) 
	int dbPort = 8080;	 			// Der Port der Datenbank
	int sePort = 4444; 				// Der Selenium-Port
	String docType = "all";			// persons, letters, writings, diaries, news, oder all
	int	maxLen = 300;					// Höchstanzahl der zu testenden Daten aus der Liste
	String timeOut = "20000";		// Timeout beim Warten auf eine Seite in ms (auf Chrepps Rechner mind. 5s)
	String browser = "firefox";
	
	/********* Einstellungen *********/
	
	String condition(String type) {
		//System.out.println(type);
		if(type == "persons") return "" +
			"selenium.isElementPresent(\"//*[@id='personSummary']//h1\");" + // Falls es ein h1 gibt, wurde Ajax geladen
			"selenium.isElementPresent(\"//*[@id='bioSummary']\");" +
			"selenium.isElementPresent(\"//*[@id='contacts']//div\");"; // Falls es ein div gibt, wurde Ajax geladen
		//"selenium.isElementPresent(\"//*[@id='iconography']\");"; // Kann man nicht so richtig testen
		else if(type == "letters") return "" +
			"selenium.isElementPresent(\"//*[@id='letterFrame']//h1\");" +
			"selenium.isElementPresent(\"//*[@id='editorial']//h1\");" +		// Editorial
			"selenium.isElementPresent(\"//*[@id='context']//h3\");" +			// Korrespondenzstelle
			"selenium.isElementPresent(\"//*[@id='knownPersons']//li\");" +		// Personen (bekannt)
			"selenium.isElementPresent(\"//*[@id='unknownPersons']//li\");" +	// Personen (unbekannt)
			"selenium.isElementPresent(\"//*[@id='places']//li\");" +			// Orte
			"selenium.isElementPresent(\"//*[@id='works']//li\");" +			// Werke
			"selenium.isElementPresent(\"//*[@id='characters']//li\");";		// Rollen
		else if(type == "lettersXML") return "selenium.isElementPresent(\"//*[@id='letterFrame']//div\");";
		else if(type == "diaries") return "" +
			"selenium.isElementPresent(\"//*[@id='diaryFrame']//h1\");" +
			"selenium.isElementPresent(\"//*[@id='editorial']//h1\");" +		// Editorial
			"selenium.isElementPresent(\"//*[@id='context']//h3\");" +			// Kontext
			"selenium.isElementPresent(\"//*[@id='knownPersons']//li\");" +		// Personen (bekannt)
			"selenium.isElementPresent(\"//*[@id='places']//li\");" +			// Orte
			"selenium.isElementPresent(\"//*[@id='works']//li\");" +			// Werke
			"selenium.isElementPresent(\"//*[@id='characters']//li\");";		// Rollen
		else if(type == "writings") return "" +
			"selenium.isElementPresent(\"//*[@id='docFrame']//h1\");" +
			"selenium.isElementPresent(\"//*[@id='editorial']//h1\");" +		// Editorial
			"selenium.isElementPresent(\"//*[@id='knownPersons']//li\");" +		// Personen (bekannt)
			"selenium.isElementPresent(\"//*[@id='places']//li\");" +			// Orte
			"selenium.isElementPresent(\"//*[@id='works']//li\");" +			// Werke
			"selenium.isElementPresent(\"//*[@id='characters']//li\");";		// Rollen
		else if(type == "news") return "" +
			"selenium.isElementPresent(\"//*[@id='newsFrame']//h1\");" +
			"selenium.isElementPresent(\"//*[@id='context']//h3\");" +			// Kontext
			"selenium.isElementPresent(\"//*[@id='knownPersons']//li\");" +		// Personen (bekannt)
			"selenium.isElementPresent(\"//*[@id='places']//li\");" +			// Orte
			"selenium.isElementPresent(\"//*[@id='works']//li\");" +			// Werke
			"selenium.isElementPresent(\"//*[@id='characters']//li\");";		// Rollen
		else return "";
	}
	
	BufferedReader buildInput(String docType) throws Exception {
		URL url = null;
		try{ url = new URL(dbProto+"://"+dbHost+":"+dbPort+dbSubFolder+"dev/ID-List.xql?type="+docType+"&maxLen="+maxLen); }
		catch(Exception e) { }
		BufferedReader idFile = new BufferedReader(new InputStreamReader(url.openStream(),"UTF-8"));
		return idFile;
	}
	
	@Before
	public void setUp() throws Exception {
		selenium = new DefaultSelenium(seHost, sePort, "*"+browser, dbProto+"://"+dbHost+":"+dbPort+dbSubFolder);
		selenium.start();
	}
	
	@Test	
	public void test() throws Exception {
		if(docType=="all") {
			String[] allDocTypes = {"persons", "letters", "writings", "diaries", "news"};
			for(int i=0;i<allDocTypes.length;i++) {
				startTest(allDocTypes[i]);
			}
		}
		else startTest(docType);
	}
	
	void startTest(String type) throws Exception {
		BufferedReader input = buildInput(type);
		String id = null;
		while((id = input.readLine()) != null) {
			try {
				openURL(id,type,"de");
				openURL(id,type,"en");
				}
			catch(SeleniumException e) {System.out.println("\n"+id+" nicht korrekt geladen: "+e);}
		}
	}
	
	String getTabName(String type, String lang) {
		if(type.equals("bio")) if(lang=="de") return "link=Biographie";		else return "link=Biography";
		if(type.equals("xml")) if(lang=="de") return "link=XML";			else return "link=XML";
		if(type.equals("dnb")) if(lang=="de") return "link=DNB";			else return "link=DNB";
		if(type.equals("bl"))  if(lang=="de") return "link=Rückverweise";	else return "link=Backlinks";
		if(type.equals("brt")) if(lang=="de") return "link=Brieftext";		else return "link=Text of Letter";
		if(type.equals("txt")) if(lang=="de") return "link=Text";			else return "link=Text";
		if(type.equals("dtx")) if(lang=="de") return "link=Dokumenttext";	else return "link=Text of document";
		else return "";
		
	}
	
	public void openURL(String id, String docType, String lang) throws Exception {
		//id ="WeGA_Jähns_1834-12-03_01";
		id = URLEncoder.encode(id, "UTF-8");
		selenium.open(dbSubFolder+lang+'/'+id);
		//System.out.print(id+":");
		if(docType == "persons" | docType == "all") {
			selenium.click(getTabName("bio",lang));
			//System.out.print("Bio,");
			selenium.waitForCondition(condition("persons"), timeOut);
			selenium.click(getTabName("xml",lang));
			//System.out.print("XML,");
			selenium.waitForCondition("selenium.isElementPresent(\"//*[@id='personDetails']//div\")", timeOut);
			/*if(selenium.isElementPresent("link=Wikipedia")) { 
			 selenium.click("link=Wikipedia");
			 //System.out.print("Wiki,");
			 selenium.waitForCondition("selenium.isElementPresent(\"//*[@id='wikipediaFrame']//div\") | selenium.isTextPresent(\"Kein Wikipedia Eintrag gefunden.\")", timeOut); // Hier DIV oder SPAN
			 }*/
			if(selenium.isElementPresent(getTabName("dnb",lang))) {
				selenium.click(getTabName("dnb",lang));
				//System.out.print("DNB,");
				selenium.waitForCondition("selenium.isElementPresent(\"//*[@id='dnbFrame']//ul\")", timeOut);
			}
			if(selenium.isElementPresent(getTabName("bl",lang))) {
				selenium.click(getTabName("bl",lang));
				//System.out.print("BL");
				selenium.waitForCondition("selenium.isElementPresent(\"//*[@id='backlinkFrame']/h2\") | selenium.isTextPresent(\"Keine Dokumente verweisen auf diesen Personeneintrag.\") | selenium.isTextPresent(\"No documents are linked to this person's entry.\")", timeOut);
			}
			//System.out.println(";");
		}
		else if(docType == "letters" | docType == "all") {
			selenium.click(getTabName("brt",lang));
			selenium.waitForCondition(condition("letters"), timeOut);
			selenium.click(getTabName("xml",lang));
			selenium.waitForCondition("selenium.isElementPresent(\"//*[@id='letterFrame']//div\")", timeOut);
		}
		else if(docType == "diaries" | docType == "all") {
			selenium.click(getTabName("txt",lang));
			selenium.waitForCondition(condition("diaries"), timeOut);
			selenium.click(getTabName("xml",lang));
			selenium.waitForCondition("selenium.isElementPresent(\"//*[@id='diaryFrame']//div\")", timeOut);
		}
		else if(docType == "writings" | docType == "all") {
			selenium.click(getTabName("dtx",lang));
			selenium.waitForCondition(condition("writings"), timeOut);
			selenium.click(getTabName("xml",lang));
			selenium.waitForCondition("selenium.isElementPresent(\"//*[@id='docFrame']//div\")", timeOut);
		}
		else if(docType == "news" | docType == "all") {
			selenium.click(getTabName("txt",lang));
			selenium.waitForCondition(condition("news"), timeOut);
			selenium.click(getTabName("xml",lang));
			selenium.waitForCondition("selenium.isElementPresent(\"//*[@id='newsFrame']//div\")", timeOut);
		}
	}
	
	@After
	public void tearDown() throws Exception {
		selenium.stop();
	}
}