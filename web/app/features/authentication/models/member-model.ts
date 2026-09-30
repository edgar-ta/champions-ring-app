enum RegistrationStatus {
    completed,
    uncompleted
}

interface Member {
    name: string;
    lastName: string;
    birthDate: Date;
    email: string;
    phone: string;
    photoUrl: string;
    registrationStatus: RegistrationStatus;
    hasGrant: boolean;
}
