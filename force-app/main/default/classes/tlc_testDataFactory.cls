/**
 * @description       : 
 * @author            : SALESFORCE
 * @group             : 
 * @last modified on  : 02-21-2024
 * @last modified by  : Nilyan Berti
 * Modifications Log
 * Ver   Date         Author                                                Modification
 * 1.0   02-12-2024   SALESFORCE   Initial Version
**/
@isTest
public with sharing class tlc_testDataFactory {
    User User = new User();    
	String orgId = UserInfo.getOrganizationId();
    String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','') ;
	Integer randomId = Integer.valueOf(Math.rint(Math.random()*1000000));
	String uniqueName = orgId + dateString + RandomId;
	public String getUniqueName() {return this.uniqueName;}
	public void setUniqueName(String value) {this.uniqueName = value;}
	public tlc_testDataFactory withProfile(string valueEnglish, string valueSpanish){
	Profile pf = [SELECT Id FROM Profile 
                    WHERE Name = :valueEnglish 
                    OR Name = :valueSpanish];
		user.ProfileId = pf.id;
		return this;
	}

    public tlc_testDataFactory withProfileId(string value){
        user.ProfileId = value;
        return this;
    }
    public tlc_testDataFactory withLastname(string value){
        user.Lastname = value;
        return this;
    }
    public tlc_testDataFactory withfistName(string value){
        user.FirstName = value;
        return this;
    }
    public tlc_testDataFactory withManagerId(string value){
        user.ManagerId = value;
        return this;
    }
    public tlc_testDataFactory withManagerId(User manager){
        user.ManagerId = manager.Id;
        return this;
    }
    public tlc_testDataFactory isActive(Boolean value){
        user.IsActive = value;
        return this;
    }
    public tlc_testDataFactory withRole(UserRole role){
        user.UserRoleId = role.id;
        return this;
    }
    public tlc_testDataFactory withRoleId(id roleId){
        user.UserRoleId = roleId;
        return this;
    }

    
    public tlc_testDataFactory withTitle(String value){
        user.title = value;
        return this;
    }
    public tlc_testDataFactory withTimeZoneSidKey(String value){
        user.TimeZoneSidKey = value;
        return this;
    }
    public tlc_testDataFactory withEmailEncodingKey(String value){
        user.EmailEncodingKey = value;
        return this;
    }
    public tlc_testDataFactory withLocaleSidKey(String value){
        user.LocaleSidKey = value;
        return this;
    }
    public tlc_testDataFactory withLanguageLocaleKey(String value){
        user.LanguageLocaleKey = value;
        return this;
    }

    public User build(){
        user.Alias = uniqueName.substring(28, 33);
        user.email = uniqueName + '@test' + orgId + '.org';
        user.Username = uniqueName + '@test' + orgId + '.org';
        return user;
    }
    public User build(Integer indx) {
        uniqueName = uniqueName.substring(0, uniqueName.length() - 1) + indx;
        return build();
    }
    public static tlc_testDataFactory anUser(){
        return new tlc_testDataFactory();
    }



}