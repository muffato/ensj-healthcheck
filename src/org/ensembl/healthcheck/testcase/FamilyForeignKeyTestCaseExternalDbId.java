/*
  Copyright (C) 2003 EBI, GRL
 
  This library is free software; you can redistribute it and/or
  modify it under the terms of the GNU Lesser General Public
  License as published by the Free Software Foundation; either
  version 2.1 of the License, or (at your option) any later version.
 
  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
  Lesser General Public License for more details.
 
  You should have received a copy of the GNU Lesser General Public
  License along with this library; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

package org.ensembl.healthcheck.testcase;

import java.sql.*;

import org.ensembl.healthcheck.*;

import org.ensembl.healthcheck.util.*;

/**
 * An EnsEMBL Healthcheck test case that looks for broken foreign-key relationships.
 */

public class FamilyForeignKeyTestCaseExternalDbId extends EnsTestCase {
  
  /**
   * Create an OrphanTestCase that applies to a specific set of databases.
   */
  public FamilyForeignKeyTestCaseExternalDbId() {
      databaseRegexp = "^ensembl_family_.*";
      addToGroup("family_db_constraints");
      setDescription("Check for broken foreign-key relationships in ensembl_family databases.");
  }
  
  public TestResult run() {
    
    boolean result = true;
    
    DatabaseConnectionIterator it = getDatabaseConnectionIterator();
    int orphans = 0;
    
    while (it.hasNext()) {
      
      Connection con = (Connection)it.next();

      if( getRowCount( con, "select count(*) from external_db" ) > 0 ) {
        orphans = countOrphans(con, "family_members", "external_db_id", "external_db", "external_db_id", true );
        if( orphans > 0 ) {
          ReportManager.problem(this, con, "external <- family_members has unlinked entries");
        } else {
          ReportManager.correct(this, con, "external <- family_members relationships OK");
        }
      }
      
      result &= (orphans == 0);

    }
    
    return new TestResult(getShortTestName(), result);
    
  }
  
} // OrphanTestCase
