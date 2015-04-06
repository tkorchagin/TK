// Environment code for project Loco.mas2j
import jason.asSyntax.*;
import jason.environment.*;
import java.util.logging.*;
import java.io.*;
import java.util.*;
import java.lang.*;
import java.math.*;

public class uth_ss_team_Env extends Environment {
	
    private Logger logger = Logger.getLogger("auctions" + ".mas2j." + uth_ss_team_Env.class.getName());
	
	private Integer perceptsDisabled = new Integer(0);
	

	FileReader FReader;
	BufferedReader BufReader;
	PrintWriter writer;
    BufferedWriter BufWriter;
	FileWriter FWriter;
	
	
	protected static Term enable_percepts = Literal.parseLiteral("enable_percepts");
    protected static Term disable_percepts = Literal.parseLiteral("disable_percepts");
	
    protected static boolean envIsOk = false;
	protected int endCounter = 0;
	
	protected int Debug_mode = 0;

    /** Called before the MAS execution with the args informed in .mas2j */

    @Override

    public void init(String[] args) {

        super.init(args);

		LoadFromFile("./uth_ss_team_input_TK_Parts.txt"); // TK
		//LoadFromFile("./uth_ss_team_input_TK.txt"); // TK
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
		
	
    @Override

    public boolean executeAction(String agName, Structure action) {

        boolean res = false;
		if (action.equals(enable_percepts)) {
			enablePercepts();
			res = true;
        } else if (action.equals(disable_percepts)) {
			disablePercepts();
			res = true;
		} else if (action.getTerm(0).toString().contains("plan_begin")) {
			String filename = "./team_tell_output.txt"; // TK
			try {
				File file = new File(filename);
				FWriter = new FileWriter(file);
				BufWriter = new BufferedWriter(FWriter);
				res = true;
			} catch(Exception e) {
				System.out.println(e);
				res = false;
			}			
		}  else if (action.getTerm(0).toString().contains("plan_end")) {
			try {
				BufWriter.close();
				res = true;
			} catch(Exception e) {
				System.out.println(e);
				res = false;
			}
		} else if (action.getFunctor().contains("start_writing")) {
			String filename = "./" + action.getTerm(0).toString()+".txt"; // TK

			try {
				File file = new File(filename);
				FWriter = new FileWriter(file);
				BufWriter = new BufferedWriter(FWriter);
				res = true;
			} catch(Exception e) {
				System.out.println(e);
				res = false;
			}
		} else if (action.getFunctor().contains("end_writing")) {
			try {
				BufWriter.close();
				res = true;
			} catch(Exception e) {
				System.out.println(e);
				res = false;
			}
		} else if (action.getFunctor().contains("write_next")) {  
			// Parsing of loco input data and transforming them into Jason format
			String terminator;
			if(action.getFunctor().contains("line")) 
				terminator = "\r\n";
			else
				terminator = "; ";
			String line = action.getTerm(0).toString() + terminator;
					line = line.replace(',',';');			// -----//-----//-----//-----//----
					line = line.replace('.',',');			// two lines needed if csv in prepared in the russian format
			try {
				BufWriter.write(line);
				res = true;
			} catch(Exception e) {
				System.out.println(e);
				res = false;
			}
		} else if (action.getFunctor().contains("start_loading")) {
			String s = action.getTerm(0).toString();
			String inputFile = s.substring(1,s.length()-1);		// get rid of quotes
			
											// the first term must be the name (w/o extention)
			try {													// of the csv-file
				FReader = new FileReader(inputFile);
				BufReader = new BufferedReader(FReader);
				res = true;
			} catch(Exception e) {
				System.out.println(e);
				res = false;
			}
		} else if (action.getFunctor().contains("end_loading")) {
			try {
				BufReader.close();
				res = true;
			} catch(Exception e) {
				System.out.println(e);
				res = false;
			}
		} else if (action.getFunctor().contains("parse_string")) {
			// dep2000037816_dir21_7
			String agent_name = action.getTerm(0).toString();
			String s = action.getTerm(1).toString();
			String dir = "dir";
			String separator = "_";
			
			String direction = "";
			String partN = "";
			
			int dir_index = s.lastIndexOf(dir);
			int separator_index = s.lastIndexOf(separator);
			
			if(dir_index != -1 & separator_index != -1){
				direction = s.substring(dir_index+dir.length(), separator_index);
				partN = s.substring(separator_index + separator.length());
			} else {
				direction = "--";
				partN = "--";
			}
			
			String parsed_percept = "parsed(" +s+ "," +direction+ "," +partN+ ")";
			addPercept(agent_name, Literal.parseLiteral(parsed_percept));
			
			res = true;
		}
		updatePercepts();
		return res;
    }
	
	private void LoadFromFile(String fileName) {
		String line;				
		try {
			FileReader fr = new FileReader(fileName);
			BufferedReader br = new BufferedReader(fr);
			while ((line = br.readLine()) != null) {				
				String msg = line.substring(1);	
				if (line.charAt(0) == '+') {
					addPercept("uth_ss_team_main", Literal.parseLiteral(msg));
				} else {
					removePercept("uth_ss_team_main", Literal.parseLiteral(msg));
				}
			}
			br.close();
		} catch(Exception e) {
			System.out.println(e);
		}
	}
}
