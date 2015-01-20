// Environment code for project Loco.mas2j
import jason.asSyntax.*;
import jason.environment.*;
import java.util.logging.*;
import java.io.*;
import java.util.*;
import java.lang.*;
import java.math.*;

public class lines_Env extends Environment {
	
    private Logger logger = Logger.getLogger("auctions.mas2j." + lines_Env.class.getName());
	
	private Integer perceptsDisabled = new Integer(0);
	
	private Integer Dim = new Integer(8);
	
	private String agent = "main";


	FileReader FReader;
	BufferedReader BufReader;
	PrintWriter writer;
    BufferedWriter BufWriter;
	FileWriter FWriter;
	
	
	protected static Term enable_percepts = Literal.parseLiteral("enable_percepts");
    protected static Term disable_percepts = Literal.parseLiteral("disable_percepts");
    protected static boolean envIsOk = false;
	protected int endCounter = 0;

    /** Called before the MAS execution with the args informed in .mas2j */

    @Override

    public void init(String[] args) {

        super.init(args);
		
		Dim = 170;
		//addPercept(agent, Literal.parseLiteral("debug"));

		updatePercepts();
    }

	
	java.awt.event.ActionListener listener = null;

	public void addActionListener(java.awt.event.ActionListener l) {
		listener = l;
	}
	
	public void actionPerformed(java.awt.event.ActionEvent event) {
		if (listener != null) {
			listener.actionPerformed(event);
		}
	}

	Structure lastAct = null;

	public Structure getLastAct() {
		return lastAct;
	}
	
	public void enablePercepts() {
		synchronized (perceptsDisabled) {
			if (perceptsDisabled > 0)
				perceptsDisabled--;
		}
	}

	public void disablePercepts() {
		synchronized (perceptsDisabled) {
			perceptsDisabled++;
		}
	}
	
	public java.util.List<Literal> getPercepts(java.lang.String agName)	{
		synchronized (perceptsDisabled) {
			if (perceptsDisabled == 0)
				return super.getPercepts(agName);
		}
		return null;
	}

	
	private void updatePercepts() {
	}

	
	public void debug(int i) {
		logger.info(Integer.toString(i));
	}
	
	public void debug(String s) {
		logger.info(s);
	}

		
	
    @Override

    public boolean executeAction(String agName, Structure action) {

        boolean res = false;
		if (action.equals(enable_percepts)) {
			enablePercepts();
			res = true;
        }
		else if (action.equals(disable_percepts)) {
			disablePercepts();
			res = true;
		}  else if (action.getFunctor().contains("tell")) {
			res = true;
		} else if (action.getFunctor().contains("load_data")) {  
			String inputFile = "util.txt";  
			try {													// of the csv-file
				FReader = new FileReader(inputFile);
				BufReader = new BufferedReader(FReader);
				res = true;
			} catch(Exception e) {
				System.out.println(e);
				res = false;
			}
			// Parsing of team input data and transforming them into Jason format
			String line,fact,name,mode;
			String[] args;
			fact = "dimension("+ Dim +")";
			addPercept(agent, Literal.parseLiteral(fact));
			try {
				for(int i=1;i<=Dim;i++) {
					line = BufReader.readLine();
					//debug(1);
					//line = line.replace(',','.');			// two lines needed if csv in prepared in the russian format 
					line = line.replace(';',',');			// -----//-----//-----//-----//----
					//line = line.replaceAll("[ ]+",",");		// -----//-----//-----//-----//----
					line = line.trim();
					//debug(line);
					//args = line.split("[ ]+");
					args = line.split(",");
					if( line != null) {
						for(int j=1;j<=Dim;j++) {
								fact = "utility(" + i + ",[" + line + "])";
								addPercept(agent, Literal.parseLiteral(fact));
						}
					}
				}
			} catch(Exception e) {
				System.out.println(e);
				res = false;
			}
			try {
				BufReader.close();
				res = true;
			} catch(Exception e) {
				System.out.println(e);
				res = false;
			}
		} 
		updatePercepts();
		return res;
    }

}


