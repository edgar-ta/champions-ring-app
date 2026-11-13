import type { Receptionist } from "../models/receptionist-model";

    export interface ReceptionistRepository {
        login(email: string, password: string): Promise<void> ;
        
        getMembers(): Promise<Member[]> ;

        getReceptionistData(): Promise<Receptionist> ;

        updateReceptionistData(receptionist: Receptionist): Promise<void> ;

        getStatistics(): Promise<Statistics> ;
}   