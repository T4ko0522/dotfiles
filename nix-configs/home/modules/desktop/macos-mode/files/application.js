ObjC.import('AppKit');

function run(argv) {
    const applications = $.NSRunningApplication.runningApplicationsWithBundleIdentifier(argv[0]);
    if (argv[1] === 'terminate') {
        for (let index = 0; index < applications.count; index++) {
            if (!applications.objectAtIndex(index).terminate) {
                throw new Error('Application refused normal termination');
            }
        }
    }
    return applications.count > 0 ? 'running' : 'stopped';
}
